{{ config(
  materialized = 'view'
) }}

SELECT
  TO_TIMESTAMP(
    block_timestamp / 1000000000
  ) AS block_timestamp,
  event_id,
  rune_address,
  rune_amt,
  DATEADD(
    ms,
    __HEVO__LOADED_AT,
    '1970-01-01'
  ) AS _INSERTED_TIMESTAMP
FROM
  {{ ref('bronze__tcy_distribution_events') }}
  qualify(ROW_NUMBER() over(PARTITION BY rune_address, rune_amt, block_timestamp
ORDER BY
  __HEVO__LOADED_AT DESC)) = 1