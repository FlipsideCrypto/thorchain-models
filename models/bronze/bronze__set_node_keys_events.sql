{{ config(
  materialized = 'view'
) }}

SELECT
  node_addr,
  secp256k1,
  ed25519,
  validator_consensus,
  event_id,
  block_timestamp,
  __HEVO__DATABASE_NAME,
  __HEVO__SCHEMA_NAME,
  __HEVO__INGESTED_AT,
  __HEVO__LOADED_AT
FROM
  {{ source(
    'thorchain_midgard',
    'midgard_set_node_keys_events'
  ) }}
WHERE 
  block_timestamp >= 1647913096219785087

UNION ALL

SELECT
  node_addr,
  secp256k1,
  ed25519,
  validator_consensus,
  event_id,
  block_timestamp,
  __HEVO__DATABASE_NAME,
  __HEVO__SCHEMA_NAME,
  __HEVO__INGESTED_AT,
  __HEVO__LOADED_AT
FROM
  {{ source(
    'thorchain_midgard_archive',
    'midgard_set_node_keys_events'
  ) }}
WHERE 
  block_timestamp < 1647913096219785087