{{ config(
  materialized = 'view'
) }}

SELECT
  pool,
  asset_tx,
  asset_chain,
  asset_addr,
  asset_e8,
  rune_tx,
  rune_addr,
  rune_e8,
  pending_type,
  event_id,
  block_timestamp,
  __HEVO__DATABASE_NAME,
  __HEVO__SCHEMA_NAME,
  __HEVO__INGESTED_AT,
  __HEVO__LOADED_AT
FROM
  {{ source(
    'thorchain_midgard',
    'midgard_pending_liquidity_events'
  ) }}
WHERE 
  block_timestamp >= 1647913096219785087

UNION ALL

SELECT
  pool,
  asset_tx,
  asset_chain,
  asset_addr,
  asset_e8,
  rune_tx,
  rune_addr,
  rune_e8,
  pending_type,
  event_id,
  block_timestamp,
  __HEVO__DATABASE_NAME,
  __HEVO__SCHEMA_NAME,
  __HEVO__INGESTED_AT,
  __HEVO__LOADED_AT
FROM
  {{ source(
    'thorchain_midgard_archive',
    'midgard_pending_liquidity_events'
  ) }}
WHERE 
  block_timestamp < 1647913096219785087