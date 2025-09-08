{{ config(
  materialized = 'view'
) }}

SELECT
  tx_id,
  COALESCE(
    admin_address,
    ''
  ) AS admin_address,
  block_timestamp,
  code_id,
  COALESCE(
    contract_address,
    ''
  ) AS contract_address,
  event_id,
  COALESCE(
    funds,
    ''
  ) AS funds,
  COALESCE(
    label,
    ''
  ) AS label,
  COALESCE(
    msg,
    ''
  ) AS msg,
  COALESCE(
    sender,
    ''
  ) AS sender,
  __HEVO__LOADED_AT
FROM
  {{ source(
    'thorchain_midgard',
    'midgard_instantiate_events'
  ) }}