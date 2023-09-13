{{ config(
  materialized = 'table',
  meta ={ 'database_tags':{ 'table':{ 'PURPOSE': 'DEX, AMM' }} }
) }}

SELECT
  *
FROM
  {{ ref('gov__fact_set_version_events') }}
