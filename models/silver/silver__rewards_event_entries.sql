{{ config(
  materialized = 'view'
) }}

SELECT
  pool AS pool_name,
  rune_e8,
  event_id,
  block_timestamp,
  DATEADD(
    ms,
    __HEVO__LOADED_AT,
    '1970-01-01'
  ) AS _INSERTED_TIMESTAMP
FROM
  {{ ref('bronze__rewards_event_entries') }}
  qualify(ROW_NUMBER() over(PARTITION BY event_id, pool, block_timestamp
ORDER BY
  __HEVO__LOADED_AT DESC)) = 1
