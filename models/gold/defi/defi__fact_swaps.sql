{{ config(
  materialized = 'incremental',
  meta ={ 'database_tags':{ 'table':{ 'PURPOSE': 'DEX, AMM, SWAPS' }} },
  unique_key = 'fact_swaps_id',
  incremental_strategy = 'merge',
  cluster_by = ['block_timestamp::DATE']
) }}

WITH base AS (

  SELECT
    block_timestamp,
    block_id,
    tx_id,
    blockchain,
    pool_name,
    from_address,
    native_to_address,
    to_pool_address,
    affiliate_address,
    affiliate_fee_basis_points,
    from_asset,
    to_asset,
    from_amount,
    to_amount,
    min_to_amount,
    from_amount_usd,
    to_amount_usd,
    rune_usd,
    asset_usd,
    to_amount_min_usd,
    swap_slip_bp,
    liq_fee_rune,
    liq_fee_rune_usd,
    liq_fee_asset,
    liq_fee_asset_usd,
    streaming_count,
    streaming_quantity,
    _unique_key,
    _inserted_timestamp
  FROM
    {{ ref('silver__swaps') }}

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
  ) }} AS fact_swaps_id,
  b.block_timestamp,
  COALESCE(
    b.dim_block_id,
    '-1'
  ) AS dim_block_id,
  tx_id,
  blockchain,
  pool_name,
  from_address,
  native_to_address,
  to_pool_address,
  affiliate_address,
  affiliate_fee_basis_points,
  from_asset,
  to_asset,
  from_amount,
  to_amount,
  min_to_amount,
  from_amount_usd,
  to_amount_usd,
  rune_usd,
  asset_usd,
  to_amount_min_usd,
  swap_slip_bp,
  liq_fee_rune,
  liq_fee_rune_usd,
  liq_fee_asset,
  liq_fee_asset_usd,
  streaming_count,
  streaming_quantity,
  A._inserted_timestamp,
  '{{ env_var("DBT_CLOUD_RUN_ID", "manual") }}' AS _audit_run_id
FROM
  base A
  LEFT JOIN {{ ref('core__dim_block') }}
  b
  ON A.block_id = b.block_id
