{{ config(
  materialized = 'incremental',
  meta ={ 'database_tags':{ 'table':{ 'PURPOSE': 'DEX, AMM, SWAPS' }} },
  unique_key = 'fact_streamling_swap_details_events_id',
  incremental_strategy = 'merge',
  cluster_by = ['block_timestamp::DATE']
) }}

WITH base AS (

  SELECT
    tx_id,
    INTERVAL,
    quantity,
    COUNT,
    last_height,
    deposit_asset,
    deposit_e8,
    in_asset,
    in_e8,
    out_asset,
    out_e8,
    failed_swaps,
    failed_swaps_reasons,
    event_id,
    block_timestamp,
    failed_swap_reasons,
    _INSERTED_TIMESTAMP
  FROM
    {{ ref('silver__streamling_swap_details_events') }}

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
  {{ dbt_utils.generate_surrogate_key(
    ['a.event_id']
  ) }} AS fact_streamling_swap_details_events_id,
  b.block_timestamp,
  COALESCE(
    b.dim_block_id,
    '-1'
  ) AS dim_block_id,
  tx_id,
  INTERVAL,
  quantity,
  COUNT,
  last_height,
  deposit_asset,
  deposit_e8,
  in_asset,
  in_e8,
  out_asset,
  out_e8,
  failed_swaps,
  failed_swaps_reasons,
  event_id,
  failed_swap_reasons,
  A._inserted_timestamp,
  '{{ invocation_id }}' AS _audit_run_id,
  SYSDATE() AS inserted_timestamp,
  SYSDATE() AS modified_timestamp
FROM
  base A
  LEFT JOIN {{ ref('core__dim_block') }}
  b
  ON A.block_timestamp = b.timestamp
