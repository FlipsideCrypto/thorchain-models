{{ config(
  materialized = 'incremental',
  meta ={ 'database_tags':{ 'table':{ 'PURPOSE': 'DEX, AMM' }} },
  unique_key = 'fact_upgrades_id',
  incremental_strategy = 'merge',
  incremental_predicates = ['DBT_INTERNAL_DEST.block_timestamp >= (select min(block_timestamp) from ' ~ generate_tmp_view_name(this) ~ ')'], 
  cluster_by = ['block_timestamp::DATE']
) }}

WITH base AS (

  SELECT
    block_id,
    tx_id,
    from_address,
    to_address,
    burn_asset,
    rune_amount,
    rune_amount_usd,
    mint_amount,
    mint_amount_usd,
    _unique_key,
    _INSERTED_TIMESTAMP
  FROM
    {{ ref('silver__upgrades') }}
)
SELECT
  {{ dbt_utils.generate_surrogate_key(
    ['a._unique_key']
  ) }} AS fact_upgrades_id,
  b.block_timestamp,
  COALESCE(
    b.dim_block_id,
    '-1'
  ) AS dim_block_id,
  tx_id,
  from_address,
  to_address,
  burn_asset,
  rune_amount,
  rune_amount_usd,
  mint_amount,
  mint_amount_usd,
  A._inserted_timestamp,
  '{{ invocation_id }}' AS _audit_run_id,
  SYSDATE() AS inserted_timestamp,
  SYSDATE() AS modified_timestamp
FROM
  base A
  JOIN {{ ref('core__dim_block') }}
  b
  ON A.block_id = b.block_id
{% if is_incremental() %}
WHERE
  b.block_timestamp >= (
    SELECT
      MAX(
        block_timestamp - INTERVAL '1 HOUR'
      )
    FROM
      {{ this }}
  ) 
{% endif %}