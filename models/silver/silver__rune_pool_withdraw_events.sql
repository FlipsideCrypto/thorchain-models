{{ config(
  materialized = 'view'
) }}

SELECT
  tx_id,
  rune_addr AS rune_address,
  amount_e8,
  units,
  basis_points,
  affiliate_basis_pts AS affiliate_basis_points,
  affiliate_amount_e8,
  affiliate_addr AS affiliate_address,
  event_id,
  block_timestamp,
  DATEADD(
    ms,
    __HEVO__LOADED_AT,
    '1970-01-01'
  ) AS _INSERTED_TIMESTAMP
FROM
  {{ ref(
    'bronze__rune_pool_withdraw_events'
  ) }}
QUALIFY(
  ROW_NUMBER() OVER (
    PARTITION BY event_id
    ORDER BY __HEVO__LOADED_AT DESC
  ) = 1
)