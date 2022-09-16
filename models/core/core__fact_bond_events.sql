{{ config(
  materialized = 'incremental',
  unique_key = 'fact_bond_events_id',
  incremental_strategy = 'merge',
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
    memo,
    bond_type,
    e8,
    block_timestamp,
    concat_ws(
      '-',
      tx_id :: STRING,
      from_address :: STRING,
      to_address :: STRING,
      asset_e8 :: STRING,
      bond_type :: STRING,
      e8 :: STRING,
      block_timestamp :: STRING,
      blockchain :: STRING,
      asset :: STRING,
      memo :: STRING
    ) AS _unique_key,
    _INSERTED_TIMESTAMP
  FROM
    {{ ref('silver__bond_events') }}

{% if is_incremental() %}
WHERE
  _inserted_timestamp >= (
    SELECT
      MAX(
        _inserted_timestamp
      )
    FROM
      {{ this }}
  )
{% endif %}
)
SELECT
  {{ dbt_utils.surrogate_key(
    ['a._unique_key']
  ) }} AS fact_bond_events_id,
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
  memo,
  bond_type,
  e8,
  A._INSERTED_TIMESTAMP,
  '{{ env_var("DBT_CLOUD_RUN_ID", "manual") }}' AS _audit_run_id
FROM
  base A
  LEFT JOIN {{ ref('core__dim_block') }}
  b
  ON A.block_timestamp = b.timestamp
