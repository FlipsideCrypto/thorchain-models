{{ config(
  materialized = 'incremental',
  meta={
    'database_tags':{
        'table': {
            'PURPOSE': 'DEX, AMM, STAKING'
        }
    }
  },
  unique_key = 'fact_swap_events_id',
  incremental_strategy = 'merge',
  cluster_by = ['block_timestamp::DATE']
) }}

WITH base AS (

  SELECT
    tx_id,
    blockchain,
    from_address,
    to_address,
    from_asset,
    from_e8,
    to_asset,
    to_e8,
    memo,
    pool_name,
    to_e8_min,
    swap_slip_bp,
    liq_fee_e8,
    liq_fee_in_rune_e8,
    _DIRECTION,
    event_id,
    block_timestamp,
    _INSERTED_TIMESTAMP
  FROM
    {{ ref('silver__swap_events') }}

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
    ['a.event_id','a.tx_id','a.blockchain','a.to_address','a.from_address','a.from_asset','a.from_e8','a.to_asset','a.to_e8','a.memo','a.pool_name','a._direction']
  ) }} AS fact_swap_events_id,
  b.block_timestamp,
  COALESCE(
    b.dim_block_id,
    '-1'
  ) AS dim_block_id,
  tx_id,
  blockchain,
  from_address,
  to_address,
  from_asset,
  from_e8,
  to_asset,
  to_e8,
  memo,
  pool_name,
  to_e8_min,
  swap_slip_bp,
  liq_fee_e8,
  liq_fee_in_rune_e8,
  _DIRECTION,
  event_id,
  A._inserted_timestamp,
  '{{ env_var("DBT_CLOUD_RUN_ID", "manual") }}' AS _audit_run_id
FROM
  base A
  LEFT JOIN {{ ref('core__dim_block') }}
  b
  ON A.block_timestamp = b.timestamp
