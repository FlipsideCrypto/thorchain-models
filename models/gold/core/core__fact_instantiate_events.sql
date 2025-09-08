{{ config(
  materialized = 'incremental',
  meta ={ 'database_tags':{ 'table':{ 'PURPOSE': 'CONTRACTS' }} },
  unique_key = 'fact_instantiate_events_id',
  incremental_strategy = 'merge',
  incremental_predicates = ['DBT_INTERNAL_DEST.block_timestamp >= (select min(block_timestamp) from ' ~ generate_tmp_view_name(this) ~ ')'], 
  cluster_by = ['block_timestamp::DATE']
) }}

WITH base AS (

  SELECT
    tx_id,
    admin_address,
    block_timestamp,
    code_id,
    contract_address,
    event_id,
    funds,
    label,
    msg,
    sender,
    _INSERTED_TIMESTAMP
  FROM
    {{ ref('silver__instantiate_events') }}
)
SELECT
  {{ dbt_utils.generate_surrogate_key(
    ['a.tx_id','a.contract_address','a.code_id','a.block_timestamp','a.admin_address','a.sender','a.label','a.msg','a.funds']
  ) }} AS fact_instantiate_events_id,
  b.block_timestamp,
  COALESCE(
    b.dim_block_id,
    '-1'
  ) AS dim_block_id,
  tx_id,
  admin_address,
  code_id,
  contract_address,
  event_id,
  funds,
  label,
  msg,
  sender,
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
  A.block_timestamp >= (
    SELECT
      MAX(block_timestamp)
    FROM
      {{ this }}
  )
{% endif %}