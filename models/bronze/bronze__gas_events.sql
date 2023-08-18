{{ config(
  materialized = 'view'
) }}

SELECT
  asset,
  asset_e8,
  rune_e8,
  tx_count,
  event_id,
  block_timestamp,
  __HEVO__DATABASE_NAME,
  __HEVO__SCHEMA_NAME,
  __HEVO__INGESTED_AT,
  __HEVO__LOADED_AT
FROM
  {{ source(
    'thorchain_midgard',
    'midgard_gas_events'
  ) }}
