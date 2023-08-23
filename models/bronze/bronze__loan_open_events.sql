{{ config(
  materialized = 'view'
) }}

SELECT
  owner,
  collateral_up,
  debt_up,
  collateralization_ratio,
  collateral_asset,
  target_asset,
  event_id,
  block_timestamp,
  __HEVO__DATABASE_NAME,
  __HEVO__SCHEMA_NAME,
  __HEVO__INGESTED_AT,
  __HEVO__LOADED_AT
FROM
  {{ source(
    'thorchain_midgard',
    'midgard_loan_open_events'
  ) }}
