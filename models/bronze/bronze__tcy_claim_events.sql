{{ config(
  materialized = 'view'
) }}

SELECT
    tx_id,
    rune_address,
    l1_address,
    asset,
    tcy_amt,
    memo,
    event_id,
    block_timestamp,
    __HEVO__DATABASE_NAME,
    __HEVO__SCHEMA_NAME,
    __HEVO__INGESTED_AT,
    __HEVO__LOADED_AT
FROM
  {{ source(
    'thorchain_midgard',
    'midgard_tcy_claim_events'
  ) }}
