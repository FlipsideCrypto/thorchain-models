

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
  THORCHAIN_DEV.silver.block_pool_depths
  bpd
  JOIN THORCHAIN_DEV.silver.block_log
  b
  ON bpd.block_timestamp = b.timestamp
  LEFT JOIN THORCHAIN_DEV.silver.prices
  p
  ON b.height = p.block_id
  AND bpd.pool_name = p.pool_name

