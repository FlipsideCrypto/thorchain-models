{{ config(
  materialized = 'incremental',
  meta ={ 'database_tags':{ 'table':{ 'PURPOSE': 'DEX, AMM' }} },
  unique_key = 'fact_gas_events_id',
  incremental_strategy = 'merge',
  cluster_by = ['block_timestamp::DATE']
) }}

WITH base AS (

  SELECT
    asset,
    asset_e8,
    rune_e8,
    tx_count,
    event_id,
    block_timestamp,
    _INSERTED_TIMESTAMP
  FROM
    {{ ref('silver__gas_events') }}

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
  OR asset IN (
    SELECT
      asset
    FROM
      {{ this }}
    WHERE
      dim_block_id = '-1'
  )
{% endif %}
)
SELECT
  {{ dbt_utils.generate_surrogate_key(
    ['a.event_id','a.asset','a.block_timestamp']
  ) }} AS fact_gas_events_id,
  b.block_timestamp,
  COALESCE(
    b.dim_block_id,
    '-1'
  ) AS dim_block_id,
  asset,
  asset_e8,
  rune_e8,
  tx_count,
  A._INSERTED_TIMESTAMP,
  '{{ invocation_id }}' AS _audit_run_id,
  SYSDATE() AS inserted_timestamp,
  SYSDATE() AS modified_timestamp
FROM
  base A
  LEFT JOIN {{ ref('core__dim_block') }}
  b
  ON A.block_timestamp = b.timestamp
