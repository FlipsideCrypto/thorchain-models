{{ config(
  materialized = 'view'
) }}

SELECT
  tx_id,
  amount,
  TO_TIMESTAMP(
    block_timestamp / 1000000000
  ) AS block_timestamp,
  event_id,
  memo,
  rune_address,
  DATEADD(
    ms,
    __HEVO__LOADED_AT,
    '1970-01-01'
  ) AS _INSERTED_TIMESTAMP
FROM
  {{ ref('bronze__tcy_stake_events') }}
  qualify(ROW_NUMBER() over(PARTITION BY tx_id, rune_address, amount, block_timestamp, COALESCE(memo, '')
ORDER BY
  __HEVO__LOADED_AT DESC)) = 1