{{ config(
  materialized = 'view'
) }}

SELECT
  fail_reason,
  is_unicast,
  blame_nodes,
  ROUND,
  height,
  event_id,
  block_timestamp,
  __HEVO__DATABASE_NAME,
  __HEVO__SCHEMA_NAME,
  __HEVO__INGESTED_AT,
  __HEVO__LOADED_AT
FROM
  {{ source(
    'thorchain_midgard',
    'midgard_tss_keygen_failure_events'
  ) }}
WHERE 
  block_timestamp >= 1647913096219785087

UNION ALL

SELECT
  fail_reason,
  is_unicast,
  blame_nodes,
  ROUND,
  height,
  event_id,
  block_timestamp,
  __HEVO__DATABASE_NAME,
  __HEVO__SCHEMA_NAME,
  __HEVO__INGESTED_AT,
  __HEVO__LOADED_AT
FROM
  {{ source(
    'thorchain_midgard_archive',
    'midgard_tss_keygen_failure_events'
  ) }}
WHERE 
  block_timestamp < 1647913096219785087