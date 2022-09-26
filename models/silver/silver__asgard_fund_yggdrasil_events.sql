{{ config(
  materialized = 'view'
) }}

SELECT
  tx AS tx_id,
  asset,
  asset_e8,
  vault_key,
  event_id,
  block_timestamp,
  event_id,
  DATEADD(
    ms,
    __HEVO__LOADED_AT,
    '1970-01-01'
  ) AS _INSERTED_TIMESTAMP
FROM
  {{ ref('bronze__asgard_fund_yggdrasil_events') }}
  qualify(ROW_NUMBER() over(PARTITION BY event_id, tx, asset, asset_e8, vault_key, block_timestamp
ORDER BY
  __HEVO__LOADED_AT DESC)) = 1
