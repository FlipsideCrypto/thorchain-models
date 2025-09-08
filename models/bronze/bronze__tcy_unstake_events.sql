{{ config(
  materialized = 'view'
) }}

SELECT
  tx_id,
  amount,
  block_timestamp,
  event_id,
  COALESCE(
    memo,
    ''
  ) AS memo,
  COALESCE(
    rune_address,
    ''
  ) AS rune_address,
  __HEVO__LOADED_AT
FROM
  {{ source(
    'thorchain_midgard',
    'midgard_tcy_unstake_events'
  ) }}