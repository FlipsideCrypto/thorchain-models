{{ config(
  materialized = 'view',
  meta={
    'database_tags':{
        'table': {
            'PURPOSE': 'DEX, AMM'
        }
    }
  }
) }}

WITH base AS (

  SELECT
    pool_name,
    asset,
    asset_e8,
    event_id,
    block_timestamp,
    _INSERTED_TIMESTAMP
  FROM
    {{ ref('silver__slash_amounts') }}

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
    ['a.event_id','a.pool_name','a.asset']
  ) }} AS fact_slash_amounts_id,
  b.block_timestamp,
  COALESCE(
    b.dim_block_id,
    '-1'
  ) AS dim_block_id,
  pool_name,
  asset,
  asset_e8,
  A._INSERTED_TIMESTAMP,
  '{{ env_var("DBT_CLOUD_RUN_ID", "manual") }}' AS _audit_run_id
FROM
  base A
  LEFT JOIN {{ ref('core__dim_block') }}
  b
  ON A.block_timestamp = b.timestamp
