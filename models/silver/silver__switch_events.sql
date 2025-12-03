{{ config(
  materialized = 'view'
) }}

SELECT
  tx AS tx_id,
  from_addr AS from_address,
  to_addr AS to_address,
  burn_asset,
  burn_e8,
  mint_e8,
  mint_asset,
  event_id,
  block_timestamp,
  DATEADD(
    ms,
    __HEVO__LOADED_AT,
    '1970-01-01'
  ) AS _INSERTED_TIMESTAMP
FROM
  {{ ref('bronze__switch_events') }}
  qualify(ROW_NUMBER() over(PARTITION BY tx, from_addr, to_addr, burn_asset, burn_e8, mint_e8, block_timestamp
ORDER BY
  __HEVO__LOADED_AT DESC)) = 1
