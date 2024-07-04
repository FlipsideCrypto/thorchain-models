{{ config(
  materialized = 'view'
) }}

SELECT
  chain,
  to_addr,
  asset,
  asset_e8,
  asset_decimals,
  gas_rate,
  memo,
  in_hash,
  out_hash,
  max_gas_amount,
  max_gas_decimals,
  max_gas_asset,
  module_name,
  vault_pub_key,
  event_id,
  block_timestamp,
  __HEVO__DATABASE_NAME,
  __HEVO__SCHEMA_NAME,
  __HEVO__INGESTED_AT,
  __HEVO__LOADED_AT
FROM
  {{ source(
    'thorchain_midgard',
    'midgard_scheduled_outbound_events'
  ) }}
