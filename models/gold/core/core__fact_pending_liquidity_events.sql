{{ config(
  materialized = 'view',
  meta ={ 'database_tags':{ 'table':{ 'PURPOSE': 'DEX, AMM' }} }
) }}

SELECT
  *
FROM
  {{ ref('defi__fact_pending_liquidity_events') }}
