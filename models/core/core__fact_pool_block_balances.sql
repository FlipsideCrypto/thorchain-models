{{ config(
  materialized = 'incremental',
  unique_key = 'fact_pool_block_balances_id',
  incremental_strategy = 'merge',
  cluster_by = ['block_timestamp::DATE']
) }}

WITH base AS (

  SELECT
    block_id,
    pool_name,
    rune_amount,
    rune_amount_usd,
    asset_amount,
    asset_amount_usd,
    synth_amount,
    synth_amount_usd,
    _unique_key,
    _INSERTED_TIMESTAMP
  FROM
    {{ ref('silver__pool_block_balances') }}

{% if is_incremental() %}
WHERE
  _inserted_timestamp >= (
    SELECT
      MAX(
        _inserted_timestamp
      )
    FROM
      {{ this }}
  ) - INTERVAL '4 HOURS'
{% endif %}
)
SELECT
  {{ dbt_utils.surrogate_key(
    ['a._unique_key']
  ) }} AS fact_pool_block_balances_id,
  b.block_timestamp,
  COALESCE(
    b.dim_block_id,
    '-1'
  ) AS dim_block_id,
  pool_name,
  rune_amount,
  rune_amount_usd,
  asset_amount,
  asset_amount_usd,
  synth_amount,
  synth_amount_usd,
  A._INSERTED_TIMESTAMP,
  '{{ env_var("DBT_CLOUD_RUN_ID", "manual") }}' AS _audit_run_id
FROM
  base A
  LEFT JOIN {{ ref('core__dim_block') }}
  b
  ON A.block_id = b.block_id
