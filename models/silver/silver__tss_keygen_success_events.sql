{{ config(
  materialized = 'view'
) }}

SELECT
  pub_key,
  members,
  height,
  event_id,
  block_timestamp,
  DATEADD(
    ms,
    __HEVO__LOADED_AT,
    '1970-01-01'
  ) AS _INSERTED_TIMESTAMP
FROM
  {{ ref('bronze__tss_keygen_success_events') }}
  e qualify(ROW_NUMBER() over(PARTITION BY event_id
ORDER BY
  __HEVO__INGESTED_AT DESC)) = 1
