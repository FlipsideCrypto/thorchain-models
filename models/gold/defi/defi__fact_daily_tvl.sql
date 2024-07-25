{{ config(
  materialized = 'incremental',
  meta ={ 'database_tags':{ 'table':{ 'PURPOSE': 'DEX, AMM' }} },
  unique_key = 'fact_daily_tvl_id',
  incremental_strategy = 'merge',
  incremental_predicates = ['DBT_INTERNAL_DEST.day >= (select min(day) from ' ~ generate_tmp_view_name(this) ~ ')'], 
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
  ) 
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
  '{{ invocation_id }}' AS _audit_run_id,
  SYSDATE() AS inserted_timestamp,
  SYSDATE() AS modified_timestamp
FROM
  base A
