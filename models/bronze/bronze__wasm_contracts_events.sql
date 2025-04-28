{{ config(
  materialized = 'view'
) }}

SELECT
  tx_id,
  contract_address,
  contract_type,
  sender,
  attributes,
  event_id,
  block_timestamp,
  __HEVO__DATABASE_NAME,
  __HEVO__SCHEMA_NAME,
  __HEVO__INGESTED_AT,
  __HEVO__LOADED_AT
FROM
  {{ source(
    'thorchain_midgard',
    'midgard_wasm_contracts_events'
  ) }}
