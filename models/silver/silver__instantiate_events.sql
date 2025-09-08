{{ config(
  materialized = 'view'
) }}

SELECT
  tx_id,
  admin_address,
  TO_TIMESTAMP(
    block_timestamp / 1000000000
  ) AS block_timestamp,
  code_id,
  contract_address,
  event_id,
  funds,
  label,
  msg,
  sender,
  DATEADD(
    ms,
    __HEVO__LOADED_AT,
    '1970-01-01'
  ) AS _INSERTED_TIMESTAMP
FROM
  {{ ref('bronze__instantiate_events') }}
  qualify(ROW_NUMBER() over(PARTITION BY tx_id, contract_address, code_id, block_timestamp, COALESCE(admin_address, ''), COALESCE(sender, ''), COALESCE(label, ''), COALESCE(msg, ''), COALESCE(funds, '')
ORDER BY
  __HEVO__LOADED_AT DESC)) = 1