{{ config(
  materialized = 'view'
) }}

SELECT
  in_tx,
  asset,
  asset_e8,
  rune_e8,
  event_id,
  block_timestamp,
  __HEVO_XMIN,
  __HEVO__DATABASE_NAME,
  __HEVO__SCHEMA_NAME,
  __HEVO__INGESTED_AT,
  __HEVO__LOADED_AT
FROM
  {{ source(
    'thorchain_midgard',
    'midgard_errata_events'
  ) }}
