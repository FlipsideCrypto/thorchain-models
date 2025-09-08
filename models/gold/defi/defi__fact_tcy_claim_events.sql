{{ config(
  materialized = 'incremental',
  meta ={ 'database_tags':{ 'table':{ 'PURPOSE': 'DEX, AMM' }} },
  unique_key = 'fact_tcy_claim_events_id',
  incremental_strategy = 'merge',
  incremental_predicates = ['DBT_INTERNAL_DEST.block_timestamp >= (select min(block_timestamp) from ' ~ generate_tmp_view_name(this) ~ ')'], 
  cluster_by = ['block_timestamp::DATE']
) }}

WITH base AS (

  SELECT
    tx_id,
    asset,
    block_timestamp,
    event_id,
    l1_address,
    memo,
    rune_address,
    tcy_amt,
    _INSERTED_TIMESTAMP
  FROM
    {{ ref('silver__tcy_claim_events') }}
)
SELECT
  {{ dbt_utils.generate_surrogate_key(
    ['a.tx_id','a.rune_address','a.tcy_amt','a.block_timestamp','a.asset','a.l1_address','a.memo']
  ) }} AS fact_tcy_claim_events_id,
  b.block_timestamp,
  COALESCE(
    b.dim_block_id,
    '-1'
  ) AS dim_block_id,
  tx_id,
  asset,
  event_id,
  l1_address,
  memo,
  rune_address,
  tcy_amt,
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