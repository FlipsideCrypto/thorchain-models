{{ config(
  materialized = 'incremental',
  meta ={ 'database_tags':{ 'table':{ 'PURPOSE': 'DEX, AMM' }} },
  unique_key = 'fact_refund_events_id',
  incremental_strategy = 'merge',
  incremental_predicates = ["DBT_INTERNAL_DEST._inserted_timestamp" >= datediff(day, -3, current_date)], 
  cluster_by = ['block_timestamp::DATE']
) }}

WITH base AS (

  SELECT
    tx_id,
    blockchain,
    from_address,
    to_address,
    asset,
    asset_e8,
    asset_2nd,
    asset_2nd_e8,
    memo,
    code,
    reason,
    event_id,
    block_timestamp,
    _TX_TYPE,
    _INSERTED_TIMESTAMP
  FROM
    {{ ref('silver__refund_events') }}

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
    ['a.event_id','a.tx_id','a.blockchain','a.from_address' ,'a.to_address','a. asset', 'a.asset_2nd', 'a.memo', 'a.code', 'a.reason', 'a.block_timestamp']
  ) }} AS fact_refund_events_id,
  b.block_timestamp,
  COALESCE(
    b.dim_block_id,
    '-1'
  ) AS dim_block_id,
  tx_id,
  blockchain,
  from_address,
  to_address,
  asset,
  asset_e8,
  asset_2nd,
  asset_2nd_e8,
  memo,
  code,
  reason,
  A._INSERTED_TIMESTAMP,
  '{{ invocation_id }}' AS _audit_run_id,
  SYSDATE() AS inserted_timestamp,
  SYSDATE() AS modified_timestamp
FROM
  base A
  LEFT JOIN {{ ref('core__dim_block') }}
  b
  ON A.block_timestamp = b.timestamp
