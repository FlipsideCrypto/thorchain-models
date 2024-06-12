{{ config(
  materialized = 'view'
) }}

SELECT
  tx,
  COALESCE(
    chain,
    ''
  ) AS chain,
  COALESCE(
    from_addr,
    ''
  ) AS from_addr,
  COALESCE(
    to_addr,
    ''
  ) AS to_addr,
  COALESCE(
    asset,
    ''
  ) AS asset,
  asset_e8,
  COALESCE(
    memo,
    ''
  ) AS memo,
  COALESCE(
    bond_type,
    ''
  ) AS bond_type,
  e8,
  block_timestamp,
  event_id,
  __HEVO__LOADED_AT
FROM
  {{ source(
    'thorchain_midgard',
    'midgard_bond_events'
  ) }}
WHERE 
  block_timestamp >= 1647913096219785087

UNION ALL

SELECT
  tx,
  COALESCE(
    chain,
    ''
  ) AS chain,
  COALESCE(
    from_addr,
    ''
  ) AS from_addr,
  COALESCE(
    to_addr,
    ''
  ) AS to_addr,
  COALESCE(
    asset,
    ''
  ) AS asset,
  asset_e8,
  COALESCE(
    memo,
    ''
  ) AS memo,
  COALESCE(
    bond_type,
    ''
  ) AS bond_type,
  e8,
  block_timestamp,
  event_id,
  __HEVO__LOADED_AT
FROM
  {{ source(
    'thorchain_midgard_archive',
    'midgard_bond_events'
  ) }}
WHERE 
  block_timestamp < 1647913096219785087
