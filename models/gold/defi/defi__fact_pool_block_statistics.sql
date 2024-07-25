{{ config(
  materialized = 'incremental',
  meta ={ 'database_tags':{ 'table':{ 'PURPOSE': 'DEX, AMM' }} },
  unique_key = 'fact_pool_block_statistics_id',
  incremental_strategy = 'merge',
  incremental_predicates = ['DBT_INTERNAL_DEST.day >= (select min(day) from ' ~ generate_tmp_view_name(this) ~ ')'], 
  cluster_by = ['day']
) }}

WITH base AS (

  SELECT
    DAY,
    add_asset_liquidity_volume,
    add_liquidity_count,
    add_liquidity_volume,
    add_rune_liquidity_volume,
    asset,
    asset_depth,
    asset_price,
    asset_price_usd,
    average_slip,
    impermanent_loss_protection_paid,
    rune_depth,
    status,
    swap_count,
    swap_volume,
    to_asset_average_slip,
    to_asset_count,
    to_asset_fees,
    to_asset_volume,
    to_rune_average_slip,
    to_rune_count,
    to_rune_fees,
    to_rune_volume,
    totalfees,
    unique_member_count,
    unique_swapper_count,
    units,
    withdraw_asset_volume,
    withdraw_count,
    withdraw_rune_volume,
    withdraw_volume,
    total_stake,
    depth_product,
    synth_units,
    pool_units,
    liquidity_unit_value_index,
    prev_liquidity_unit_value_index,
    _UNIQUE_KEY
  FROM
    {{ ref('silver__pool_block_statistics') }}

{% if is_incremental() %}
WHERE
  DAY >= (
    SELECT
      MAX(
        DAY
      )
    FROM
      {{ this }}
  ) 
{% endif %}
)
SELECT
  {{ dbt_utils.generate_surrogate_key(
    ['a._unique_key']
  ) }} AS fact_pool_block_statistics_id,
  DAY,
  add_asset_liquidity_volume,
  add_liquidity_count,
  add_liquidity_volume,
  add_rune_liquidity_volume,
  asset,
  asset_depth,
  asset_price,
  asset_price_usd,
  average_slip,
  impermanent_loss_protection_paid,
  rune_depth,
  status,
  swap_count,
  swap_volume,
  to_asset_average_slip,
  to_asset_count,
  to_asset_fees,
  to_asset_volume,
  to_rune_average_slip,
  to_rune_count,
  to_rune_fees,
  to_rune_volume,
  totalfees,
  unique_member_count,
  unique_swapper_count,
  units,
  withdraw_asset_volume,
  withdraw_count,
  withdraw_rune_volume,
  withdraw_volume,
  total_stake,
  depth_product,
  synth_units,
  pool_units,
  liquidity_unit_value_index,
  prev_liquidity_unit_value_index,
  '{{ invocation_id }}' AS _audit_run_id,
  SYSDATE() AS inserted_timestamp,
  SYSDATE() AS modified_timestamp
FROM
  base A
