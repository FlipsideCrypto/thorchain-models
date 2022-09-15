{{ config(
  materialized = 'view'
) }}

SELECT
  tx AS tx_id,
  chain AS blockchain,
  from_addr AS from_address,
  to_addr AS to_address,
  asset,
  asset_e8,
  memo,
  rune_e8,
  pool AS pool_name,
  event_id,
  block_timestamp,
  DATEADD(
    ms,
    __HEVO__LOADED_AT,
    '1970-01-01'
  ) AS _INSERTED_TIMESTAMP
FROM
  {{ ref('bronze__add_events') }}
  qualify(ROW_NUMBER() over(PARTITION BY event_id, tx, chain, from_addr, to_addr, asset, memo, pool, block_timestamp
ORDER BY
  __HEVO__INGESTED_AT DESC)) = 1
