{{ config(
  materialized = 'view'
) }}

SELECT
  owner,
  {# collateral_down,
  debt_down,
  #}
  collateral_asset,
  event_id,
  block_timestamp,
  collateral_withdrawn,
  debt_repaid,
  tx_id,
  __HEVO__DATABASE_NAME,
  __HEVO__SCHEMA_NAME,
  __HEVO__INGESTED_AT,
  __HEVO__LOADED_AT
FROM
  {{ source(
    'thorchain_midgard',
    'midgard_loan_repayment_events'
  ) }}
