{{ config(
  materialized = 'incremental',
  meta ={ 'database_tags':{ 'table':{ 'PURPOSE': 'DEX, AMM' }} },
  unique_key = 'event_id',
  incremental_strategy = 'merge',
  incremental_predicates = ['DBT_INTERNAL_DEST.block_timestamp >= (select min(block_timestamp) from ' ~ generate_tmp_view_name(this) ~ ')'], 
  cluster_by = ['block_timestamp::DATE']
) }}

WITH base AS (

  SELECT
    amount_e8,
    asset,
    asset_address,
    rune_address,
    tx_id,
    event_id,
    block_timestamp,
    _INSERTED_TIMESTAMP
  FROM
    {{ ref('silver__trade_account_deposit_events') }}
)
SELECT
  {{ dbt_utils.generate_surrogate_key(
    ['a.amount_e8','a.asset','a.asset_address','a.rune_address','a.tx_id','a.event_id','a.block_timestamp']
  ) }} AS fact_trade_account_deposits_events_id,
  b.block_timestamp,
  COALESCE(
    b.dim_block_id,
    '-1'
  ) AS dim_block_id,
  amount_e8,
  asset,
  asset_address,
  rune_address,
  tx_id,
  event_id,
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
  OR event_id IN (
    SELECT
      event_id
    FROM
      {{ this }}
    WHERE
      dim_block_id = '-1'
  )
{% endif %}