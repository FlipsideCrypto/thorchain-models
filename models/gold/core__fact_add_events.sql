{{ config(
  materialized = 'incremental',
  meta ={ 'database_tags':{ 'table':{ 'PURPOSE': 'DEX, AMM' }}},
  unique_key = 'fact_add_events_id',
  incremental_strategy = 'merge',
  cluster_by = ['block_timestamp::DATE']
) }}

WITH base AS (

  SELECT
    e.block_timestamp,
    e.tx_id,
    e.rune_e8,
    e.blockchain,
    e.asset_e8,
    e.pool_name,
    e.memo,
    e.to_address,
    e.from_address,
    e.asset,
    e.event_id,
    _inserted_timestamp
  FROM
    {{ ref('silver__add_events') }}
    e

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
  OR tx_id IN (
    SELECT
      tx_id
    FROM
      {{ this }}
    WHERE
      dim_block_id = '-1'
  )
{% endif %}
)
SELECT
  {{ dbt_utils.generate_surrogate_key(
    ['a.event_id','a.tx_id','a.blockchain','a.from_address','a.to_address','a.asset','a.memo','a.block_timestamp']
  ) }} AS fact_add_events_id,
  b.block_timestamp,
  COALESCE(
    b.dim_block_id,
    '-1'
  ) AS dim_block_id,
  A.tx_id,
  A.rune_e8,
  A.blockchain,
  A.asset_e8,
  A.pool_name,
  A.memo,
  A.to_address,
  A.from_address,
  A.asset,
  A._inserted_timestamp,
  '{{ env_var("DBT_CLOUD_RUN_ID", "manual") }}' AS _audit_run_id
FROM
  base A
  LEFT JOIN {{ ref('core__dim_block') }}
  b
  ON A.block_timestamp = b.timestamp
