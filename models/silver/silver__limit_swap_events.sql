{{ config(
  materialized = 'view'
) }}

SELECT
  tx_id,
  from_addr AS from_address,
  to_addr AS to_address,
  from_asset,
  from_e8,
  to_asset,
  to_e8,
  memo,
  event_id,
  block_timestamp,
  DATEADD(
    ms,
    __HEVO__LOADED_AT,
    '1970-01-01'
  ) AS _INSERTED_TIMESTAMP
FROM
  {{ ref('bronze__limit_swap_events') }}
  qualify(ROW_NUMBER() over(PARTITION BY event_id, tx_id, from_addr, to_addr, from_asset, from_e8, to_asset, to_e8, block_timestamp
ORDER BY
  __HEVO__LOADED_AT DESC)) = 1
