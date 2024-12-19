{{ config(
  materialized = 'view'
) }}

SELECT
  tx_id,
  fee_amt,
  gross_amt,
  fee_bps,
  memo,
  asset,
  rune_address,
  thorname,
  event_id,
  block_timestamp,
  __HEVO__DATABASE_NAME,
  __HEVO__SCHEMA_NAME,
  __HEVO__INGESTED_AT,
  __HEVO__LOADED_AT
FROM
  {{ source(
    'thorchain_midgard',
    'midgard_affiliate_fee_events'
  ) }}
