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
  collateral_deposited,
  debt_issued,
  tx_id,
  block_timestamp,
  DATEADD(
    ms,
    __HEVO__LOADED_AT,
    '1970-01-01'
  ) AS _INSERTED_TIMESTAMP
FROM
  {{ ref('bronze__loan_open_events') }}
  qualify(ROW_NUMBER() over(PARTITION BY event_id
ORDER BY
  __HEVO__LOADED_AT DESC)) = 1
