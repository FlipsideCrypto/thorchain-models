{{ config(
  materialized = 'view',
  meta ={ 'database_tags':{ 'table':{ 'PURPOSE': 'DEX, AMM' }} }
) }}

SELECT
  *
FROM
  {{ ref('gov__fact_new_node_events') }}
