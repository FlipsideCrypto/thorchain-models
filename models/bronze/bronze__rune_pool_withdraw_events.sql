{{ config(
  materialized = 'view'
) }}

SELECT
  tx_id,
  rune_addr,
  amount_e8,
  units,
  basis_points,
  affiliate_basis_pts,
  affiliate_amount_e8,
  affiliate_addr,
  event_id,
  block_timestamp,
  __HEVO__DATABASE_NAME,
  __HEVO__SCHEMA_NAME,
  __HEVO__INGESTED_AT,
  __HEVO__LOADED_AT
FROM
  {{ source(
    'thorchain_midgard',
    'midgard_rune_pool_withdraw_events'
  ) }}
