{{ config(
  materialized = 'view'
) }}

SELECT
  tx,
  chain,
  from_addr,
  to_addr,
  from_asset,
  from_e8,
  to_asset,
  to_e8,
  memo,
  pool,
  to_e8_min,
  swap_slip_bp,
  liq_fee_e8,
  liq_fee_in_rune_e8,
  _DIRECTION,
  event_id,
  block_timestamp,
  streaming_count,
  streaming_quantity,
  _STREAMING,
  _TX_TYPE,
  __HEVO__DATABASE_NAME,
  __HEVO__SCHEMA_NAME,
  __HEVO__INGESTED_AT,
  __HEVO__LOADED_AT
FROM
  {{ source(
    'thorchain_midgard',
    'midgard_swap_events'
  ) }}
