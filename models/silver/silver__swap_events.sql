{{ config(
  materialized = 'view'
) }}

SELECT
  tx AS tx_id,
  chain AS blockchain,
  from_addr AS from_address,
  to_addr AS to_address,
  from_asset,
  from_e8,
  to_asset,
  to_e8,
  memo,
  pool AS pool_name,
  to_e8_min,
  swap_slip_bp,
  liq_fee_e8,
  liq_fee_in_rune_e8,
  _DIRECTION,
  event_id,
  block_timestamp,
  streaming_count,
  streaming_quantity,
  DATEADD(
    ms,
    __HEVO__LOADED_AT,
    '1970-01-01'
  ) AS _INSERTED_TIMESTAMP
FROM
  {{ ref('bronze__swap_events') }}
  qualify(ROW_NUMBER() over(PARTITION BY event_id, tx, chain, to_addr, from_addr, from_asset, from_e8, to_asset, to_e8, memo, pool, _direction
ORDER BY
  __HEVO__INGESTED_AT DESC)) = 1
