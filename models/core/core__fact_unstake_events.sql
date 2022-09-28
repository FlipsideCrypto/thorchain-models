{{ config(
  materialized = 'incremental',
  unique_key = 'fact_unstake_events_id',
  incremental_strategy = 'merge',
  cluster_by = ['block_timestamp::DATE']
) }}

WITH base AS (

  SELECT
    e.tx_id,
    e.blockchain,
    e.from_address,
    e.to_address,
    e.asset,
    e.asset_e8,
    e.emit_asset_e8,
    e.emit_rune_e8,
    e.memo,
    e.pool_name,
    e.stake_units,
    e.basis_points,
    e.asymmetry,
    e.imp_loss_protection_e8,
    e._emit_asset_in_rune_e8,
    e.block_timestamp,
    _INSERTED_TIMESTAMP
  FROM
    {{ ref('silver__unstake_events') }}
    e

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
    ['a.tx_id', 'a.blockchain', 'a.from_address', 'a.to_address', 'a.asset', 'a.asset_e8', 'a.emit_asset_e8', 'a.emit_rune_e8', 'a.memo', 'a.pool_name', 'a.stake_units', 'a.basis_points', 'a.asymmetry', 'a.imp_loss_protection_e8', 'a._emit_asset_in_rune_e8','a.block_timestamp']
  ) }} AS fact_unstake_events_id,
  b.block_timestamp,
  COALESCE(
    b.dim_block_id,
    '-1'
  ) AS dim_block_id,
  A.tx_id,
  A.blockchain,
  A.from_address,
  A.to_address,
  A.asset,
  A.asset_e8,
  A.emit_asset_e8,
  A.emit_rune_e8,
  A.memo,
  A.pool_name,
  A.stake_units,
  A.basis_points,
  A.asymmetry,
  A.imp_loss_protection_e8,
  A._emit_asset_in_rune_e8,
  A._inserted_timestamp,
  '{{ env_var("DBT_CLOUD_RUN_ID", "manual") }}' AS _audit_run_id
FROM
  base A
  LEFT JOIN {{ ref('core__dim_block') }}
  b
  ON A.block_timestamp = b.timestamp
