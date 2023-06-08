{{ config(
  materialized = 'incremental',
  meta ={ 'database_tags':{ 'table':{ 'PURPOSE': 'DEX, AMM' }}},
  unique_key = 'fact_total_value_locked_id',
  incremental_strategy = 'merge'
) }}

WITH base AS (

  SELECT
    DAY,
    total_value_pooled,
    total_value_bonded,
    total_value_locked,
    _INSERTED_TIMESTAMP
  FROM
    {{ ref('silver__total_value_locked') }}

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
  ) }} AS fact_total_value_locked_id,
  DAY,
  total_value_pooled,
  total_value_bonded,
  total_value_locked,
  _INSERTED_TIMESTAMP,
  '{{ env_var("DBT_CLOUD_RUN_ID", "manual") }}' AS _audit_run_id
FROM
  base A
