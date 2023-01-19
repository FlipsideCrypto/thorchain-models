{{ config(
  materialized = 'incremental',
  meta={
    'database_tags':{
        'table': {
            'PURPOSE': 'DEX, AMM'
        }
    }
  },
  unique_key = 'fact_daily_earnings_id',
  incremental_strategy = 'merge'
) }}

WITH base AS (

  SELECT
    DAY,
    liquidity_fees,
    liquidity_fees_usd,
    block_rewards,
    block_rewards_usd,
    total_earnings,
    total_earnings_usd,
    earnings_to_nodes,
    earnings_to_nodes_usd,
    earnings_to_pools,
    earnings_to_pools_usd,
    avg_node_count,
    _INSERTED_TIMESTAMP
  FROM
    {{ ref('silver__daily_earnings') }}

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
  {{ dbt_utils.surrogate_key(
    ['a.day']
  ) }} AS fact_daily_earnings_id,
  DAY,
  liquidity_fees,
  liquidity_fees_usd,
  block_rewards,
  block_rewards_usd,
  total_earnings,
  total_earnings_usd,
  earnings_to_nodes,
  earnings_to_nodes_usd,
  earnings_to_pools,
  earnings_to_pools_usd,
  avg_node_count,
  A._inserted_timestamp,
  '{{ env_var("DBT_CLOUD_RUN_ID", "manual") }}' AS _audit_run_id
FROM
  base A
