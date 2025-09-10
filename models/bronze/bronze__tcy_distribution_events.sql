{{ config(
  materialized = 'view'
) }}

SELECT
    rune_address,
    rune_amt,
    event_id,
    block_timestamp,
    __HEVO__DATABASE_NAME,
    __HEVO__SCHEMA_NAME,
    __HEVO__INGESTED_AT,
    __HEVO__LOADED_AT
FROM
  {{ source(
    'thorchain_midgard',
    'midgard_tcy_distribution_events'
  ) }}

