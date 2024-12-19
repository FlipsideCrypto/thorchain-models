{{ config(
  materialized = 'view'
) }}

SELECT
  tx_id,
  fee_amt,
  gross_amt,
  fee_bps,
  memo,
  asset,
  rune_address,
  thorname,
  event_id,
  block_timestamp,
  DATEADD(
    ms,
    __HEVO__LOADED_AT,
    '1970-01-01'
  ) AS _INSERTED_TIMESTAMP
FROM 
  {{ ref('bronze__affiliate_fee_events') }}
  qualify(ROW_NUMBER() over(PARTITION BY event_id, tx_id, fee_amt, gross_amt, fee_bps, memo, asset, rune_address, thorname, block_timestamp
ORDER BY
  __HEVO__LOADED_AT DESC)) = 1