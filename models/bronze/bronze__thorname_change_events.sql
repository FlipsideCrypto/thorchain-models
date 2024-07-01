{{ config(
  materialized = 'view'
) }}

SELECT
  NAME,
  chain,
  address,
  registration_fee_e8,
  fund_amount_e8,
  expire,
  owner,
  event_id,
  block_timestamp,
  __HEVO__DATABASE_NAME,
  __HEVO__SCHEMA_NAME,
  __HEVO__INGESTED_AT,
  __HEVO__LOADED_AT
FROM
  {{ source(
    'thorchain_midgard',
    'midgard_thorname_change_events'
  ) }}
WHERE 
  block_timestamp >= 1647913096219785087

UNION ALL

SELECT
  NAME,
  chain,
  address,
  registration_fee_e8,
  fund_amount_e8,
  expire,
  owner,
  event_id,
  block_timestamp,
  __HEVO__DATABASE_NAME,
  __HEVO__SCHEMA_NAME,
  __HEVO__INGESTED_AT,
  __HEVO__LOADED_AT
FROM
  {{ source(
    'thorchain_midgard_archive',
    'midgard_thorname_change_events'
  ) }}
WHERE 
  block_timestamp < 1647913096219785087