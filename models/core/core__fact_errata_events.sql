{{ config(
  materialized = 'incremental',
  unique_key = 'fact_errata_events_id',
  incremental_strategy = 'merge',
  cluster_by = ['block_timestamp::DATE']
) }}

WITH base AS (

  SELECT
    in_tx,
    asset,
    asset_e8,
    rune_e8,
    event_id,
    block_timestamp,
    concat_ws(
      '-',
      event_id :: STRING,
      in_tx :: STRING,
      asset :: STRING,
      block_timestamp :: STRING
    ) AS _unique_key,
    _INSERTED_TIMESTAMP
  FROM
    {{ ref('silver__errata_events') }}

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
  ) }} AS fact_errata_events_id,
  b.block_timestamp,
  COALESCE(
    b.dim_block_id,
    '-1'
  ) AS dim_block_id,
  asset_e8,
  rune_e8,
  in_tx,
  asset,
  A._INSERTED_TIMESTAMP,
  '{{ env_var("DBT_CLOUD_RUN_ID", "manual") }}' AS _audit_run_id
FROM
  base A
  LEFT JOIN {{ ref('core__dim_block') }}
  b
  ON A.block_timestamp = b.timestamp
