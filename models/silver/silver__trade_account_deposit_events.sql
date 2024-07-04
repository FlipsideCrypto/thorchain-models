{{ config(
  materialized = 'view'
) }}

SELECT
  amount_e8,
  asset,
  asset_address,
  rune_address,
  tx_id,
  event_id,
  block_timestamp,
  DATEADD(
    ms,
    __HEVO__LOADED_AT,
    '1970-01-01'
  ) AS _INSERTED_TIMESTAMP
FROM
  {{ ref('bronze__trade_account_deposit_events') }}