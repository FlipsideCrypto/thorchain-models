{{ config(
  materialized = 'view'
) }}

SELECT
  pool AS pool_name,
  asset_tx AS asset_tx_id,
  asset_chain AS asset_blockchain,
  asset_addr AS asset_address,
  asset_e8,
  stake_units,
  rune_tx AS rune_tx_id,
  rune_addr AS rune_address,
  rune_e8,
  _ASSET_IN_RUNE_E8,
  event_id,
  block_timestamp,
  DATEADD(
    ms,
    __HEVO__LOADED_AT,
    '1970-01-01'
  ) AS _INSERTED_TIMESTAMP
FROM
  {{ ref('bronze__stake_events') }}
  qualify(ROW_NUMBER() over(PARTITION BY event_id, pool, rune_tx, asset_chain, stake_units, rune_addr, asset_tx, asset_addr, block_timestamp
ORDER BY
  __HEVO__INGESTED_AT DESC)) = 1
