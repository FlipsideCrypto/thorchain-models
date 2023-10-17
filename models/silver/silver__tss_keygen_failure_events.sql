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
  DATEADD(
    ms,
    __HEVO__LOADED_AT,
    '1970-01-01'
  ) AS _INSERTED_TIMESTAMP
FROM
  {{ ref('bronze__tss_keygen_failure_events') }}
  e qualify(ROW_NUMBER() over(PARTITION BY event_id
ORDER BY
  __HEVO__INGESTED_AT DESC)) = 1
