{{ config(
  materialized = 'incremental',
  meta ={ 'database_tags':{ 'table':{ 'PURPOSE': 'DEX, AMM' }}},
  unique_key = 'fact_block_rewards_id',
  incremental_strategy = 'merge'
) }}

WITH base AS (

  SELECT
    DAY,
    liquidity_fee,
    block_rewards,
    earnings,
    bonding_earnings,
    liquidity_earnings,
    avg_node_count,
    _INSERTED_TIMESTAMP
  FROM
    {{ ref('silver__block_rewards') }}

{% if is_incremental() %}
WHERE
  DAY >= (
    SELECT
      MAX(
        DAY
      )
    FROM
      {{ this }}
  ) - INTERVAL '48 HOURS'
{% endif %}
)
SELECT
  {{ dbt_utils.generate_surrogate_key(
    ['a.day']
  ) }} AS fact_block_rewards_id,
  DAY,
  liquidity_fee,
  block_rewards,
  earnings,
  bonding_earnings,
  liquidity_earnings,
  avg_node_count,
  A._inserted_timestamp,
  '{{ env_var("DBT_CLOUD_RUN_ID", "manual") }}' AS _audit_run_id
FROM
  base A
