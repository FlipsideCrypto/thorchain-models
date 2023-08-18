{{ config(
  materialized = 'view'
) }}

SELECT
  height,
  TIMESTAMP,
  HASH,
  agg_state,
  __HEVO__DATABASE_NAME,
  __HEVO__SCHEMA_NAME,
  __HEVO__INGESTED_AT,
  __HEVO__LOADED_AT
FROM
  {{ source(
    'thorchain_midgard',
    'midgard_block_log'
  ) }}
