{{ config(
  materialized = 'view'
) }}

SELECT
  asset,
  rune_amt,
  rune_add,
  asset_amt,
  asset_add,
  reason,
  event_id,
  block_timestamp,
  __HEVO__DATABASE_NAME,
  __HEVO__SCHEMA_NAME,
  __HEVO__INGESTED_AT,
  __HEVO__LOADED_AT
FROM
  {{ source(
    'thorchain_midgard',
    'midgard_pool_balance_change_events'
  ) }}
WHERE 
  block_timestamp >= 1647913096219785087

UNION ALL

SELECT
  asset,
  rune_amt,
  rune_add,
  asset_amt,
  asset_add,
  reason,
  event_id,
  block_timestamp,
  __HEVO__DATABASE_NAME,
  __HEVO__SCHEMA_NAME,
  __HEVO__INGESTED_AT,
  __HEVO__LOADED_AT
FROM
  {{ source(
    'thorchain_midgard_archive',
    'midgard_pool_balance_change_events'
  ) }}
WHERE 
  block_timestamp < 1647913096219785087