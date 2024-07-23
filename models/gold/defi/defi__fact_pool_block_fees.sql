{{ config(
  materialized = 'incremental',
  meta ={ 'database_tags':{ 'table':{ 'PURPOSE': 'DEX, AMM' }} },
  unique_key = 'fact_pool_block_fees_id',
  incremental_strategy = 'merge',
  incremental_predicates = ["DBT_INTERNAL_DEST._inserted_timestamp" >= datediff(day, -2, current_date)], 
  cluster_by = ['day']
) }}

WITH base AS (

  SELECT
    DAY,
    pool_name,
    rewards,
    total_liquidity_fees_rune,
    asset_liquidity_fees,
    rune_liquidity_fees,
    earnings,
    _unique_key,
    _INSERTED_TIMESTAMP
  FROM
    {{ ref('silver__pool_block_fees') }}

{% if is_incremental() %}
WHERE
  _inserted_timestamp >= (
    SELECT
      MAX(
        _inserted_timestamp
      )
    FROM
      {{ this }}
  ) - INTERVAL '48 HOURS'
{% endif %}
)
SELECT
  {{ dbt_utils.generate_surrogate_key(
    ['a._unique_key']
  ) }} AS fact_pool_block_fees_id,
  DAY,
  pool_name,
  rewards,
  total_liquidity_fees_rune,
  asset_liquidity_fees,
  rune_liquidity_fees,
  earnings,
  A._inserted_timestamp,
  '{{ invocation_id }}' AS _audit_run_id,
  SYSDATE() AS inserted_timestamp,
  SYSDATE() AS modified_timestamp
FROM
  base A
