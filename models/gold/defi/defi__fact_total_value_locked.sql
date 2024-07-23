{{ config(
  materialized = 'incremental',
  meta ={ 'database_tags':{ 'table':{ 'PURPOSE': 'DEX, AMM' }} },
  unique_key = 'fact_total_value_locked_id',
  incremental_strategy = 'merge',
  incremental_predicates = ["DBT_INTERNAL_DEST._inserted_timestamp" >= datediff(day, -3, current_date)]
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
  '{{ invocation_id }}' AS _audit_run_id,
  SYSDATE() AS inserted_timestamp,
  SYSDATE() AS modified_timestamp
FROM
  base A
