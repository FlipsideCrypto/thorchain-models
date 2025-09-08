{{ config(
  materialized = 'view'
) }}

SELECT
  block_timestamp,
  event_id,
  COALESCE(
    rune_address,
    ''
  ) AS rune_address,
  rune_amt,
  __HEVO__LOADED_AT
FROM
  {{ source(
    'thorchain_midgard',
    'midgard_tcy_distribution_events'
  ) }}