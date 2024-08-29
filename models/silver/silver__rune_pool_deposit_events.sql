{{ config(
  materialized = 'view'
) }}

SELECT
  tx_id,
  rune_addr AS rune_address,
  amount_e8,
  units,
  event_id,
  block_timestamp,
  DATEADD(
    ms,
    __HEVO__LOADED_AT,
    '1970-01-01'
  ) AS _INSERTED_TIMESTAMP
FROM
  {{ ref(
    'bronze__rune_pool_deposit_events'
  ) }}
