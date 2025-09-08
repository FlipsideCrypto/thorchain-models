{{ config(
  materialized = 'view'
) }}

SELECT
  tx_id,
  COALESCE(
    asset,
    ''
  ) AS asset,
  block_timestamp,
  event_id,
  COALESCE(
    l1_address,
    ''
  ) AS l1_address,
  COALESCE(
    memo,
    ''
  ) AS memo,
  COALESCE(
    rune_address,
    ''
  ) AS rune_address,
  tcy_amt,
  __HEVO__LOADED_AT
FROM
  {{ source(
    'thorchain_midgard',
    'midgard_tcy_claim_events'
  ) }}