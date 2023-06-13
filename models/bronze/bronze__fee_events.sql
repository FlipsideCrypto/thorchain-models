{{ config(
  materialized = 'view'
) }}

SELECT
  tx,
  asset,
  asset_e8,
  pool_deduct,
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
    'midgard_fee_events'
  ) }}
UNION ALL
SELECT
  tx,
  asset,
  asset_e8,
  pool_deduct,
  event_id,
  block_timestamp,
  NULL AS __HEVO_XMIN,
  __HEVO__DATABASE_NAME,
  __HEVO__SCHEMA_NAME,
  __HEVO__INGESTED_AT,
  __HEVO__LOADED_AT
FROM
  {{ source(
    'thorchain_midgard_missing_data',
    'midgard_fee_events'
  ) }}
