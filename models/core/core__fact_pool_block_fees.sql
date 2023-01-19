{{ config(
  materialized = 'incremental',
  meta={
    'database_tags':{
        'table': {
            'PURPOSE': 'DEX, AMM'
        }
    }
  },
  unique_key = 'fact_pool_block_fees_id',
  incremental_strategy = 'merge',
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
  {{ dbt_utils.surrogate_key(
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
  '{{ env_var("DBT_CLOUD_RUN_ID", "manual") }}' AS _audit_run_id
FROM
  base A
