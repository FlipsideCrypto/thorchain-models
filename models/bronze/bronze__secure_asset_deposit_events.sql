{{ config(
  materialized = 'view'
) }}

SELECT
  amount_e8,
  asset,
  asset_address,
  rune_address,
  tx_id,
  event_id,
  block_timestamp,
  __HEVO__DATABASE_NAME,
  __HEVO__SCHEMA_NAME,
  __HEVO__INGESTED_AT,
  __HEVO__LOADED_AT
FROM
  {{ source(
    'thorchain_midgard',
    'midgard_secure_asset_deposit_events'
  ) }}
