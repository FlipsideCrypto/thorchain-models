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
  block_timestamp,
  DATEADD(
    ms,
    __HEVO__LOADED_AT,
    '1970-01-01'
  ) AS _INSERTED_TIMESTAMP
FROM
  {{ ref('bronze__loan_repayment_events') }}
  qualify(ROW_NUMBER() over(PARTITION BY event_id
ORDER BY
  __HEVO__LOADED_AT DESC)) = 1
