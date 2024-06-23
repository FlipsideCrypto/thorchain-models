{{ config(
  materialized = 'incremental',
  unique_key = "_unique_key",
  incremental_strategy = 'merge',
  cluster_by = ['block_timestamp::DATE']
) }}
-- block level prices by pool
-- step 1 what is the USD pool with the highest balance (aka deepest pool)
WITH blocks AS (

  SELECT
    height AS block_id,
    b.block_timestamp,
    pool_name,
    rune_e8,
    asset_e8
  FROM
    {{ ref('silver__block_pool_depths') }} A
    JOIN {{ ref('silver__block_log') }}
    b
    ON A.block_timestamp = b.timestamp

{% if is_incremental() %}
WHERE
  b.block_timestamp :: DATE >= CURRENT_DATE -7
{% endif %}
),
max_pool_blocks AS (
  SELECT
    MAX(block_id) AS max_block,
    pool_name
  FROM
    blocks
  WHERE
    pool_name IN (
      'BNB.USDT-6D8',
      'BNB.BUSD-BD1',
      'ETH.USDT-0XDAC17F958D2EE523A2206206994597C13D831EC7'
    )
  GROUP BY
    pool_name
),
reference_pool AS (
  SELECT
    bpd.block_id,
    block_timestamp,
    bpd.pool_name,
    rune_e8
  FROM
    blocks bpd
    JOIN max_pool_blocks mpb
    ON bpd.pool_name = mpb.pool_name
    AND bpd.block_id = mpb.max_block
  ORDER BY
    rune_e8 DESC
  LIMIT
    1
), -- step 2 use that pool to determine the price of rune
rune_usd_max_tbl AS (
  SELECT
    block_timestamp,
    block_id,
    asset_e8 / nullif(rune_e8,0) AS rune_usd_max
  FROM
    blocks
  WHERE
    pool_name = (
      SELECT
        pool_name
      FROM
        reference_pool
    )
),
rune_usd_sup_tbl AS (
  SELECT
    block_timestamp,
    block_id,
    AVG(rune_usd) AS rune_usd_sup
  FROM
    (
      SELECT
        block_timestamp,
        block_id,
        asset_e8 / rune_e8 AS rune_usd
      FROM
        blocks
      WHERE
        rune_e8 > 0
        AND asset_e8 > 0
    )
  GROUP BY
    block_timestamp,
    block_id
),
rune_usd AS (
  SELECT
    block_timestamp,
    block_id,
    CASE
      WHEN rune_usd_max IS NULL THEN LAG(rune_usd_max) ignore nulls over (
        ORDER BY
          block_id
      )
      ELSE rune_usd_max
    END AS rune_usd
  FROM
    (
      SELECT
        COALESCE(
          A.block_timestamp,
          b.block_timestamp
        ) AS block_timestamp,
        COALESCE(
          A.block_id,
          b.block_id
        ) AS block_id,
        rune_usd_max
      FROM
        rune_usd_max_tbl A full
        JOIN rune_usd_sup_tbl b
        ON A.block_timestamp = b.block_timestamp
        AND A.block_id = b.block_id
    )
) -- step 3 calculate the prices of assets by pool, in terms of tokens per tokens
-- and in USD for both tokens
SELECT
  DISTINCT b.block_id,
  b.block_timestamp,
  COALESCE(
    rune_e8 / asset_e8,
    0
  ) AS price_rune_asset,
  COALESCE(
    asset_e8 / rune_e8,
    0
  ) AS price_asset_rune,
  COALESCE(rune_usd * (rune_e8 / asset_e8), 0) AS asset_usd,
  COALESCE(
    rune_usd,
    0
  ) AS rune_usd,
  pool_name,
  concat_ws(
    '-',
    b.block_id :: STRING,
    pool_name :: STRING
  ) AS _unique_key
FROM
  blocks b
  JOIN rune_usd ru
  ON b.block_id = ru.block_id
WHERE
  rune_e8 > 0
  AND asset_e8 > 0
