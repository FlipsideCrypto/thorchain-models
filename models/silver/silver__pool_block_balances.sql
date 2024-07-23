{{ config(
  materialized = 'incremental',
  unique_key = '_unique_key',
  incremental_strategy = 'merge',
  incremental_predicates = ["DBT_INTERNAL_DEST._inserted_timestamp" >= datediff(day, -3, current_date)],   
  cluster_by = ['_inserted_timestamp::DATE']
) }}

SELECT
  b.block_timestamp,
  b.height AS block_id,
  bpd.pool_name,
  COALESCE(rune_e8 / pow(10, 8), 0) AS rune_amount,
  COALESCE(rune_e8 / pow(10, 8) * rune_usd, 0) AS rune_amount_usd,
  COALESCE(asset_e8 / pow(10, 8), 0) AS asset_amount,
  COALESCE(asset_e8 / pow(10, 8) * asset_usd, 0) AS asset_amount_usd,
  COALESCE(synth_e8 / pow(10, 8), 0) AS synth_amount,
  COALESCE(synth_e8 / pow(10, 8) * asset_usd, 0) AS synth_amount_usd,
  concat_ws(
    '-',
    bpd.block_timestamp,
    bpd.pool_name
  ) AS _unique_key,
  bpd._inserted_timestamp
FROM
  {{ ref('silver__block_pool_depths') }}
  bpd
  JOIN {{ ref('silver__block_log') }}
  b
  ON bpd.block_timestamp = b.timestamp
  LEFT JOIN {{ ref('silver__prices') }}
  p
  ON b.height = p.block_id
  AND bpd.pool_name = p.pool_name

{% if is_incremental() %}
WHERE
  bpd._inserted_timestamp >= (
    SELECT
      MAX(
        _inserted_timestamp
      )
    FROM
      {{ this }}
  ) - INTERVAL '48 HOURS'
{% endif %}
