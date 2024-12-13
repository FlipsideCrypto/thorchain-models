{{ config(
  materialized = 'view'
) }}

SELECT
  chain AS blockchain,
  to_addr AS to_address,
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
  DATEADD(
    ms,
    __HEVO__LOADED_AT,
    '1970-01-01'
  ) AS _INSERTED_TIMESTAMP
FROM
  {{ ref('bronze__scheduled_outbound_events') }}
QUALIFY(
  ROW_NUMBER() OVER (
    PARTITION BY event_id
    ORDER BY __HEVO__LOADED_AT DESC
  ) = 1
)