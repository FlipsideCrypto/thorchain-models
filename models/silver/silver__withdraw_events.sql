{{ config(
  materialized = 'view'
) }}

SELECT
  tx AS tx_id,
  chain AS blockchain,
  from_addr AS from_address,
  to_addr AS to_address,
  asset,
  asset_e8,
  emit_asset_e8,
  emit_rune_e8,
  memo,
  pool AS pool_name,
  stake_units,
  basis_points,
  asymmetry,
  imp_loss_protection_e8,
  _emit_asset_in_rune_e8,
  event_id,
  block_timestamp,
  _TX_TYPE,
  DATEADD(
    ms,
    __HEVO__LOADED_AT,
    '1970-01-01'
  ) AS _INSERTED_TIMESTAMP
FROM
  {{ ref(
    'bronze__withdraw_events'
  ) }}
  e qualify(ROW_NUMBER() over(PARTITION BY event_id, tx, chain, memo, stake_units, basis_points, block_timestamp, pool_name, asset, from_addr, to_addr
ORDER BY
  __HEVO__LOADED_AT DESC)) = 1
