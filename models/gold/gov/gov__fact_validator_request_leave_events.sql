{{ config(
  materialized = 'incremental',
  meta ={ 'database_tags':{ 'table':{ 'PURPOSE': 'DEX, AMM' }} },
  unique_key = 'fact_validator_request_leave_events_id',
  incremental_strategy = 'merge',
  incremental_predicates = ["DBT_INTERNAL_DEST._inserted_timestamp" >= datediff(day, -3, current_date)], 
  cluster_by = ['block_timestamp::DATE']
) }}

WITH base AS (

  SELECT
    block_timestamp,
    tx_id,
    from_address,
    node_address,
    event_id,
    _inserted_timestamp
  FROM
    {{ ref('silver__validator_request_leave_events') }}

{% if is_incremental() %}
WHERE
  _inserted_timestamp >= (
    SELECT
      MAX(
        _inserted_timestamp
      )
    FROM
      {{ this }}
  ) - INTERVAL '48 HOURS'
{% endif %}
)
SELECT
  {{ dbt_utils.generate_surrogate_key(
    ['a.event_id','a.block_timestamp','a.tx_id', 'a.from_address', 'a.node_address']
  ) }} AS fact_validator_request_leave_events_id,
  b.block_timestamp,
  COALESCE(
    b.dim_block_id,
    '-1'
  ) AS dim_block_id,
  tx_id,
  from_address,
  node_address,
  A._inserted_timestamp,
  '{{ invocation_id }}' AS _audit_run_id,
  SYSDATE() AS inserted_timestamp,
  SYSDATE() AS modified_timestamp
FROM
  base A
  LEFT JOIN {{ ref('core__dim_block') }}
  b
  ON A.block_timestamp = b.timestamp
