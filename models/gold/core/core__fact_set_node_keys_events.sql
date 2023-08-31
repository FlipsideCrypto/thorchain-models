{{ config(
  materialized = 'view',
  meta ={ 'database_tags':{ 'table':{ 'PURPOSE': 'DEX, AMM' }} }
) }}

SELECT
  *
FROM
  {{ ref('gov__fact_set_node_keys_events') }}
