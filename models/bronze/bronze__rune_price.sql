{{ config(
  materialized = 'view'
) }}

SELECT
  rune_price_e8,
  block_timestamp,
  __HEVO__DATABASE_NAME,
  __HEVO__SCHEMA_NAME,
  __HEVO__INGESTED_AT,
  __HEVO__LOADED_AT
FROM
  {{ source(
    'thorchain_midgard_price',
    'midgard_rune_price'
  ) }}
