{{ config(
  materialized = 'view',
  meta ={ 'database_tags':{ 'table':{ 'PURPOSE': 'DEX, AMM' }} }
) }}

SELECT
  *
FROM
  {{ ref('defi__fact_fee_events') }}
