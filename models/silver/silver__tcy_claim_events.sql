{{ config(
  materialized = 'view'
) }}

SELECT
  tx_id,
  asset,
  TO_TIMESTAMP(
    block_timestamp / 1000000000
  ) AS block_timestamp,
  event_id,
  l1_address,
  memo,
  rune_address,
  tcy_amt,
  DATEADD(
    ms,
    __HEVO__LOADED_AT,
    '1970-01-01'
  ) AS _INSERTED_TIMESTAMP
FROM
  {{ ref('bronze__tcy_claim_events') }}
  qualify(ROW_NUMBER() over(PARTITION BY tx_id, rune_address, tcy_amt, block_timestamp, COALESCE(asset, ''), COALESCE(l1_address, ''), COALESCE(memo, '')
ORDER BY
  __HEVO__LOADED_AT DESC)) = 1