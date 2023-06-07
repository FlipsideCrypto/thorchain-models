{{ config(
  materialized = 'incremental',
  meta ={ 'database_tags':{ 'table':{ 'PURPOSE': 'DEX, AMM' }}},
  unique_key = 'fact_daily_tvl_id',
  incremental_strategy = 'merge',
  cluster_by = ['day']
) }}

WITH base AS (

  SELECT
    DAY,
    total_value_pooled,
    total_value_pooled_usd,
    total_value_bonded,
    total_value_bonded_usd,
    total_value_locked,
    total_value_locked_usd
  FROM
    {{ ref('silver__daily_tvl') }}

{% if is_incremental() %}
WHERE
  DAY >= (
    SELECT
      MAX(
        DAY
      )
    FROM
      {{ this }}
  ) - INTERVAL '48 HOURS'
{% endif %}
)
SELECT
  {{ dbt_utils.generate_surrogate_key(
    ['a.day']
  ) }} AS fact_daily_tvl_id,
  DAY,
  total_value_pooled,
  total_value_pooled_usd,
  total_value_bonded,
  total_value_bonded_usd,
  total_value_locked,
  total_value_locked_usd,
  '{{ env_var("DBT_CLOUD_RUN_ID", "manual") }}' AS _audit_run_id
FROM
  base A
