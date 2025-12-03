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
  _TX_TYPE,
  bond_addr,
  node_addr,
  signer_addr,
  __HEVO__DATABASE_NAME,
  __HEVO__SCHEMA_NAME,
  __HEVO__INGESTED_AT,
  __HEVO__LOADED_AT
FROM
  {{ source(
    'thorchain_midgard',
    'midgard_bond_events'
  ) }}
