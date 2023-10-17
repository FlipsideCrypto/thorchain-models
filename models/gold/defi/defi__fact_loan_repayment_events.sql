{{ config(
  materialized = 'incremental',
  meta ={ 'database_tags':{ 'table':{ 'PURPOSE': 'DEX, AMM' }} },
  unique_key = 'fact_loan_repayment_events_id',
  incremental_strategy = 'merge',
  cluster_by = ['block_timestamp::DATE']
) }}

WITH base AS (

  SELECT
    owner,
    collateral_down,
    debt_down,
    collateral_asset,
    event_id,
    block_timestamp,
    collateral_withdrawn,
    debt_repaid,
    tx_id,
    _INSERTED_TIMESTAMP
  FROM
    {{ ref('silver__loan_repayment_events') }}

{% if is_incremental() %}
WHERE
  _inserted_timestamp >= (
    SELECT
      MAX(
        _inserted_timestamp
      )
    FROM
      {{ this }}
  ) - INTERVAL '48 HOURS'
{% endif %}
)
SELECT
  {{ dbt_utils.generate_surrogate_key(
    ['a.event_id']
  ) }} AS fact_loan_repayment_events_id,
  b.block_timestamp,
  COALESCE(
    b.dim_block_id,
    '-1'
  ) AS dim_block_id,
  owner,
  collateral_down,
  debt_down,
  collateral_asset,
  collateral_withdrawn,
  debt_repaid,
  tx_id,
  event_id,
  A._INSERTED_TIMESTAMP
FROM
  base A
  LEFT JOIN {{ ref('core__dim_block') }}
  b
  ON A.block_timestamp = b.timestamp
