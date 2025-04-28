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
  {{ ref('bronze__secure_asset_deposit_events') }}
  qualify(ROW_NUMBER() over(PARTITION BY event_id
ORDER BY
  __HEVO__LOADED_AT DESC)) = 1
