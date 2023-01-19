{{ config(
  materialized = 'incremental',
  meta={
    'database_tags':{
        'table': {
            'PURPOSE': 'DEX, AMM'
        }
    }
  },
  unique_key = 'fact_total_block_rewards_id',
  incremental_strategy = 'merge',
  cluster_by = ['block_timestamp::DATE']
) }}

WITH base AS (

  SELECT
    block_id,
    reward_entity,
    rune_amount,
    rune_amount_usd,
    _unique_key,
    _INSERTED_TIMESTAMP
  FROM
    {{ ref('silver__total_block_rewards') }}

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
    ['a._unique_key']
  ) }} AS fact_total_block_rewards_id,
  b.block_timestamp,
  COALESCE(
    b.dim_block_id,
    '-1'
  ) AS dim_block_id,
  reward_entity,
  rune_amount,
  rune_amount_usd,
  A._inserted_timestamp,
  '{{ env_var("DBT_CLOUD_RUN_ID", "manual") }}' AS _audit_run_id
FROM
  base A
  LEFT JOIN {{ ref('core__dim_block') }}
  b
  ON A.block_id = b.block_id
