{{ config(
  materialized = 'incremental',
  meta={
    'database_tags':{
        'table': {
            'PURPOSE': 'DEX, AMM'
        }
    }
  },
  unique_key = 'fact_update_node_account_status_events_id',
  incremental_strategy = 'merge',
  cluster_by = ['block_timestamp::DATE']
) }}

WITH base AS (

  SELECT
    block_timestamp,
    former_status,
    current_status,
    node_address,
    _inserted_timestamp
  FROM
    {{ ref('silver__update_node_account_status_events') }}

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
  {{ dbt_utils.surrogate_key(
    ['a.node_address', 'a.block_timestamp', 'a.current_status', 'a.former_status']
  ) }} AS fact_update_node_account_status_events_id,
  b.block_timestamp,
  COALESCE(
    b.dim_block_id,
    '-1'
  ) AS dim_block_id,
  former_status,
  current_status,
  node_address,
  A._inserted_timestamp,
  '{{ env_var("DBT_CLOUD_RUN_ID", "manual") }}' AS _audit_run_id
FROM
  base A
  LEFT JOIN {{ ref('core__dim_block') }}
  b
  ON A.block_timestamp = b.timestamp
