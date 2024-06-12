{{ config(
  materialized = 'view'
) }}

SELECT
  tx,
  asset,
  asset_e8,
  vault_key,
  event_id,
  block_timestamp,
  __HEVO__DATABASE_NAME,
  __HEVO__SCHEMA_NAME,
  __HEVO__INGESTED_AT,
  __HEVO__LOADED_AT
FROM
  {{ source(
    'thorchain_midgard',
    'midgard_asgard_fund_yggdrasil_events'
  ) }}
WHERE 
  block_timestamp >= 1647913096219785087

UNION ALL

SELECT
  tx,
  asset,
  asset_e8,
  vault_key,
  event_id,
  block_timestamp,
  __HEVO__DATABASE_NAME,
  __HEVO__SCHEMA_NAME,
  __HEVO__INGESTED_AT,
  __HEVO__LOADED_AT
FROM
  {{ source(
    'thorchain_midgard_archive',
    'midgard_asgard_fund_yggdrasil_events'
  ) }}
WHERE 
  block_timestamp < 1647913096219785087