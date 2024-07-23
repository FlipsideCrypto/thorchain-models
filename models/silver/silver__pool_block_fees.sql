{{ config(
  materialized = 'incremental',
  unique_key = "_unique_key",
  incremental_strategy = 'merge'
) }}

WITH all_block_id AS (

  SELECT
    DATE(
      b.block_timestamp
    ) AS DAY,
    pool_name,
    MAX(
      A._inserted_timestamp
    ) AS _inserted_timestamp
  FROM
    {{ ref('silver__block_pool_depths') }} A
    JOIN {{ ref('silver__block_log') }}
    b
    ON A.block_timestamp = b.timestamp

{% if is_incremental() %}
WHERE
  b.block_timestamp :: DATE >= (
    SELECT
      MAX(
        DAY
      )
    FROM
      {{ this }}
  ) - INTERVAL '48 HOURS'
{% endif %}
GROUP BY
  DAY,
  pool_name
),
total_pool_rewards_tbl AS (
  SELECT
    DATE(
      b.block_timestamp
    ) AS DAY,
    pool_name,
    SUM(rune_e8) AS rewards
  FROM
    {{ ref('silver__rewards_event_entries') }} A
    JOIN {{ ref('silver__block_log') }}
    b
    ON A.block_timestamp = b.timestamp

{% if is_incremental() %}
WHERE
  b.block_timestamp :: DATE >= (
    SELECT
      MAX(
        DAY
      )
    FROM
      {{ this }}
  ) - INTERVAL '48 HOURS'
{% endif %}
GROUP BY
  DAY,
  pool_name
),
total_liquidity_fees_rune_tbl AS (
  SELECT
    DATE(
      b.block_timestamp
    ) AS DAY,
    pool_name,
    SUM(liq_fee_in_rune_e8) AS total_liquidity_fees_rune
  FROM
    {{ ref('silver__swap_events') }} A
    JOIN {{ ref('silver__block_log') }}
    b
    ON A.block_timestamp = b.timestamp

{% if is_incremental() %}
WHERE
  b.block_timestamp :: DATE >= (
    SELECT
      MAX(
        DAY
      )
    FROM
      {{ this }}
  ) - INTERVAL '48 HOURS'
{% endif %}
GROUP BY
  DAY,
  pool_name
),
liquidity_fees_asset_tbl AS (
  SELECT
    DATE(block_timestamp) AS DAY,
    pool_name,
    SUM(asset_fee) AS assetLiquidityFees
  FROM
    (
      SELECT
        b.block_timestamp,
        pool_name,
        CASE
          WHEN to_asset = 'THOR.RUNE' THEN 0
          ELSE liq_fee_e8
        END AS asset_fee
      FROM
        {{ ref('silver__swap_events') }} A
        JOIN {{ ref('silver__block_log') }}
        b
        ON A.block_timestamp = b.timestamp

{% if is_incremental() %}
WHERE
  b.block_timestamp :: DATE >= (
    SELECT
      MAX(
        DAY
      )
    FROM
      {{ this }}
  ) - INTERVAL '48 HOURS'
{% endif %}
)
GROUP BY
  DAY,
  pool_name
),
liquidity_fees_rune_tbl AS (
  SELECT
    DATE(block_timestamp) AS DAY,
    pool_name,
    SUM(asset_fee) AS runeLiquidityFees
  FROM
    (
      SELECT
        b.block_timestamp,
        pool_name,
        CASE
          WHEN to_asset <> 'THOR.RUNE' THEN 0
          ELSE liq_fee_e8
        END AS asset_fee
      FROM
        {{ ref('silver__swap_events') }} A
        JOIN {{ ref('silver__block_log') }}
        b
        ON A.block_timestamp = b.timestamp

{% if is_incremental() %}
WHERE
  b.block_timestamp :: DATE >= (
    SELECT
      MAX(
        DAY
      )
    FROM
      {{ this }}
  ) - INTERVAL '48 HOURS'
{% endif %}
)
GROUP BY
  DAY,
  pool_name
)
SELECT
  A.day,
  A.pool_name,
  COALESCE((rewards / power(10, 8)), 0) AS rewards,
  COALESCE((total_liquidity_fees_rune / power(10, 8)), 0) AS total_liquidity_fees_rune,
  COALESCE((assetLiquidityFees / power(10, 8)), 0) AS asset_liquidity_fees,
  COALESCE((runeLiquidityFees / power(10, 8)), 0) AS rune_liquidity_fees,
  (
    (COALESCE(total_liquidity_fees_rune, 0) + COALESCE(rewards, 0)) / power(
      10,
      8
    )
  ) AS earnings,
  concat_ws(
    '-',
    A.day,
    A.pool_name
  ) AS _unique_key,
  _inserted_timestamp
FROM
  all_block_id A
  LEFT JOIN total_pool_rewards_tbl b
  ON A.day = b.day
  AND A.pool_name = b.pool_name
  LEFT JOIN total_liquidity_fees_rune_tbl C
  ON A.day = C.day
  AND A.pool_name = C.pool_name
  LEFT JOIN liquidity_fees_asset_tbl d
  ON A.day = d.day
  AND A.pool_name = d.pool_name
  LEFT JOIN liquidity_fees_rune_tbl e
  ON A.day = e.day
  AND A.pool_name = e.pool_name
