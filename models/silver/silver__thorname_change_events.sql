{{ config(
  materialized = 'view'
) }}

SELECT
  owner,
  chain,
  address,
  expire,
  NAME,
  fund_amount_e8,
  registration_fee_e8,
  memo,
  sender,
  tx_id,
  event_id,
  block_timestamp,
  DATEADD(
    ms,
    __HEVO__LOADED_AT,
    '1970-01-01'
  ) AS _INSERTED_TIMESTAMP
FROM
  {{ ref('bronze__thorname_change_events') }}
  qualify(ROW_NUMBER() over(PARTITION BY event_id, block_timestamp, owner, chain, address, expire, NAME
ORDER BY
  __HEVO__LOADED_AT DESC)) = 1
