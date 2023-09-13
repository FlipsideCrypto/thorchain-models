{{ config(
  materialized = 'table',
  meta ={ 'database_tags':{ 'table':{ 'PURPOSE': 'DEX, AMM' }} }
) }}

SELECT
  *
FROM
  {{ ref('defi__fact_total_block_rewards') }}
