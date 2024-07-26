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
    blockchain,
    to_address,
    asset,
    asset_e8,
    asset_decimals,
    gas_rate,
    memo,
    in_hash,
    out_hash,
    max_gas_amount,
    max_gas_decimals,
    max_gas_asset,
    module_name,
    vault_pub_key,
    event_id,
    block_timestamp,
    _INSERTED_TIMESTAMP
  FROM
    {{ ref('silver__scheduled_outbound_events') }}
  )
SELECT
  {{ dbt_utils.generate_surrogate_key(
    ['a.blockchain', 'a.to_address','a.asset','a.asset_e8','a.asset_decimals','a.gas_rate','a.memo','a.in_hash','a.out_hash','a.max_gas_amount','a.max_gas_decimals','a.max_gas_asset','a.module_name','a.vault_pub_key','a.event_id','a.block_timestamp']
  ) }} AS fact_scheduled_outbound_events_id,
  b.block_timestamp,
  COALESCE(
    b.dim_block_id,
    '-1'
  ) AS dim_block_id,
  blockchain,
  to_address,
  asset,
  asset_e8,
  asset_decimals,
  gas_rate,
  memo,
  in_hash,
  out_hash,
  max_gas_amount,
  max_gas_decimals,
  max_gas_asset,
  module_name,
  vault_pub_key,
  event_id,
  A._INSERTED_TIMESTAMP,
  '{{ invocation_id }}' AS _audit_run_id,
  SYSDATE() AS inserted_timestamp,
  SYSDATE() AS modified_timestamp
FROM
  base A
  JOIN {{ ref('core__dim_block') }}
  b
  ON A.block_timestamp = b.timestamp
{% if is_incremental() %}
WHERE
  b.block_timestamp >= (
    SELECT
      MAX(
        block_timestamp - INTERVAL '1 HOUR'
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