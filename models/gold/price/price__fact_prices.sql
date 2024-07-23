{{ config(
  materialized = 'incremental',
  meta ={ 'database_tags':{ 'table':{ 'PURPOSE': 'DEX, AMM' }} },
  unique_key = 'FACT_PRICES_ID',
  incremental_strategy = 'merge',
  incremental_predicates = ["DBT_INTERNAL_DEST.block_timestamp" >= dateadd(hour, -48, current_timestamp)], 
  cluster_by = ['block_timestamp::DATE']
) }}

WITH base AS (

  SELECT
    block_id,
    block_timestamp,
    price_rune_asset,
    price_asset_rune,
    asset_usd,
    rune_usd,
    pool_name,
    _unique_key
  FROM
    {{ ref('silver__prices') }}

{% if is_incremental() %}
WHERE
  block_timestamp :: DATE >= CURRENT_DATE -2
{% endif %}
)
SELECT
  {{ dbt_utils.generate_surrogate_key(
    ['a._unique_key']
  ) }} AS fact_prices_id,
  A.block_timestamp,
  COALESCE(
    b.dim_block_id,
    '-1'
  ) AS dim_block_id,
  price_rune_asset,
  price_asset_rune,
  asset_usd,
  rune_usd,
  pool_name,
  '{{ invocation_id }}' AS _audit_run_id,
  SYSDATE() AS inserted_timestamp,
  SYSDATE() AS modified_timestamp
FROM
  base A
  LEFT JOIN {{ ref('core__dim_block') }}
  b
  ON A.block_id = b.block_id
