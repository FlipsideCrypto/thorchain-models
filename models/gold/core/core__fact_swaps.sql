{{ config(
  materialized = 'table',
  meta ={ 'database_tags':{ 'table':{ 'PURPOSE': 'DEX, AMM, SWAPS' }} }
) }}

SELECT
  *
FROM
  {{ ref('defi__fact_swaps') }}
