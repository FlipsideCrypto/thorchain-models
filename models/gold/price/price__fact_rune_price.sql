{{ config(
  materialized = 'incremental',
  meta ={ 'database_tags':{ 'table':{ 'PURPOSE': 'DEX, AMM' }} },
  unique_key = 'fact_rune_price_id',
  incremental_strategy = 'merge'
) }}

WITH base AS (

  SELECT
    rune_price_e8,
    block_timestamp
  FROM
    {{ ref('silver__rune_price') }}

{% if is_incremental() %}
WHERE
  _inserted_timestamp >= (
      SELECT
        MAX(
          _inserted_timestamp
        )
      FROM
        {{ this }}
    ) - INTERVAL '4 HOURS'
{% endif %}
)
SELECT
  {{ dbt_utils.generate_surrogate_key(
    ['a.rune_price_e8','a.block_timestamp']
  ) }} AS fact_rune_price_id,
  rune_price_e8,
  block_timestamp,
  '{{ invocation_id }}' AS _audit_run_id,
  SYSDATE() AS inserted_timestamp,
  SYSDATE() AS modified_timestamp
FROM
  base a
