{{ config(
  materialized = 'incremental',
  meta ={ 'database_tags':{ 'table':{ 'PURPOSE': 'DEX, AMM' }} },
  unique_key = 'fact_new_node_events_id',
  incremental_strategy = 'merge',
  incremental_predicates = ['DBT_INTERNAL_DEST.block_timestamp >= (select min(block_timestamp) from ' ~ generate_tmp_view_name(this) ~ ')'], 
  cluster_by = ['block_timestamp::DATE']
) }}

WITH base AS (

  SELECT
    node_address,
    block_timestamp,
    event_id,
    _INSERTED_TIMESTAMP
  FROM
    {{ ref('silver__new_node_events') }}
)
SELECT
  {{ dbt_utils.generate_surrogate_key(
    ['a.event_id','a.node_address','a.block_timestamp']
  ) }} AS fact_new_node_events_id,
  b.block_timestamp,
  COALESCE(
    b.dim_block_id,
    '-1'
  ) AS dim_block_id,
  node_address,
  A._INSERTED_TIMESTAMP,
  '{{ invocation_id }}' AS _audit_run_id,
  SYSDATE() AS inserted_timestamp,
  SYSDATE() AS modified_timestamp
FROM
  base A
  LEFT JOIN {{ ref('core__dim_block') }}
  b
  ON A.block_timestamp = b.timestamp
{% if is_incremental() %}
WHERE
  b.block_timestamp >= (
    SELECT
      MAX(
        block_timestamp
      )
    FROM
      {{ this }}
  ) 
  OR node_address IN (
    SELECT
      node_address
    FROM
      {{ this }}
    WHERE
      dim_block_id = '-1'
  )
{% endif %}