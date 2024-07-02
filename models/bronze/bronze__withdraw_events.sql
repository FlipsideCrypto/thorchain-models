{{ config(
  materialized = 'view'
) }}

SELECT
  tx,
  chain,
  from_addr,
  to_addr,
  asset,
  asset_e8,
  emit_asset_e8,
  emit_rune_e8,
  memo,
  pool,
  stake_units,
  basis_points,
  asymmetry,
  imp_loss_protection_e8,
  _EMIT_ASSET_IN_RUNE_E8,
  event_id,
  block_timestamp,
  _TX_TYPE,
  __HEVO__DATABASE_NAME,
  __HEVO__SCHEMA_NAME,
  __HEVO__INGESTED_AT,
  __HEVO__LOADED_AT
FROM
  {{ source(
    'thorchain_midgard',
    'midgard_withdraw_events'
  ) }}
