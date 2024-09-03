{{ config(
  materialized = 'view'
) }}

SELECT
  tx_id,
  rune_addr,
  amount_e8,
  units,
  event_id,
  block_timestamp,
  __HEVO__DATABASE_NAME,
  __HEVO__SCHEMA_NAME,
  __HEVO__INGESTED_AT,
  __HEVO__LOADED_AT
FROM
  {{ source(
    'thorchain_midgard',
    'midgard_rune_pool_deposit_events'
  ) }}
