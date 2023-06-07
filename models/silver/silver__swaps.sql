{{ config(
  materialized = 'incremental',
  unique_key = '_unique_key',
  incremental_strategy = 'merge',
  cluster_by = ['_inserted_timestamp::DATE']
) }}

WITH swaps AS (

  SELECT
    tx_id,
    blockchain,
    from_address,
    to_address,
    from_asset,
    from_e8,
    to_asset,
    to_e8,
    memo,
    pool_name,
    to_e8_min,
    swap_slip_bp,
    liq_fee_e8,
    liq_fee_in_rune_e8,
    _DIRECTION,
    event_id,
    b.block_timestamp,
    b.height AS block_id,
    A._INSERTED_TIMESTAMP,
    COUNT(1) over (
      PARTITION BY tx_id
    ) AS n_tx,
    RANK() over (
      PARTITION BY tx_id
      ORDER BY
        liq_fee_e8 ASC
    ) AS rank_liq_fee
  FROM
    {{ ref('silver__swap_events') }} A
    JOIN {{ ref('silver__block_log') }}
    b
    ON A.block_timestamp = b.timestamp

{% if is_incremental() %}
WHERE
  A._INSERTED_TIMESTAMP :: DATE >= (
    SELECT
      MAX(
        _INSERTED_TIMESTAMP
      )
    FROM
      {{ this }}
  ) - INTERVAL '4 HOURS'
{% endif %}
)
SELECT
  se.block_timestamp,
  se.block_id,
  tx_id,
  blockchain,
  se.pool_name,
  from_address,
  SPLIT(
      memo,
      ':'
    ) [2] :: STRING
  AS native_to_address,
  to_address AS to_pool_address,
  CASE
    WHEN COALESCE(SPLIT(memo, ':') [4], '') = '' THEN NULL
    ELSE SPLIT(
      memo,
      ':'
    ) [4] :: STRING
  END AS affiliate_address,
  CASE
    WHEN COALESCE(SPLIT(memo, ':') [5], '') = '' THEN NULL
    ELSE SPLIT(
      memo,
      ':'
    ) [5] :: INT
  END AS affiliate_fee_basis_points,
  from_asset,
  to_asset,
  COALESCE(from_e8 / pow(10, 8), 0) AS from_amount,
  COALESCE(to_e8 / pow(10, 8), 0) AS to_amount,
  COALESCE(to_e8_min / pow(10, 8), 0) AS min_to_amount,
  CASE
    WHEN from_asset = 'THOR.RUNE' THEN COALESCE(from_e8 * rune_usd / pow(10, 8), 0)
    ELSE COALESCE(from_e8 * asset_usd / pow(10, 8), 0)
  END AS from_amount_usd,
  CASE
    WHEN (
      to_asset = 'THOR.RUNE'
      OR to_asset = 'BNB.RUNE-B1A'
    ) THEN COALESCE(to_e8 * rune_usd / pow(10, 8), 0)
    ELSE COALESCE(to_e8 * asset_usd / pow(10, 8), 0)
  END AS to_amount_usd,
  rune_usd,
  asset_usd,
  CASE
    WHEN to_asset = 'THOR.RUNE' THEN COALESCE(to_e8_min * rune_usd / pow(10, 8), 0)
    ELSE COALESCE(to_e8_min * asset_usd / pow(10, 8), 0)
  END AS to_amount_min_usd,
  swap_slip_bp,
  COALESCE(liq_fee_in_rune_e8 / pow(10, 8), 0) AS liq_fee_rune,
  COALESCE(liq_fee_in_rune_e8 / pow(10, 8) * rune_usd, 0) AS liq_fee_rune_usd,
  CASE
    WHEN to_asset = 'THOR.RUNE' THEN COALESCE(liq_fee_e8 / pow(10, 8), 0)
    ELSE COALESCE(liq_fee_e8 / pow(10, 8), 0)
  END AS liq_fee_asset,
  CASE
    WHEN to_asset = 'THOR.RUNE' THEN COALESCE(liq_fee_e8 * rune_usd / pow(10, 8), 0)
    ELSE COALESCE(liq_fee_e8 * asset_usd / pow(10, 8), 0)
  END AS liq_fee_asset_usd,
  concat_ws(
    '-',
    tx_id,
    se.block_id,
    to_asset,
    from_asset,
    COALESCE(
      native_to_address,
      ''
    ),
    from_address,
    se.pool_name,
    to_pool_address,
    event_id
  ) AS _unique_key,
  _INSERTED_TIMESTAMP
FROM
  swaps se
  LEFT JOIN {{ ref('silver__prices') }}
  p
  ON se.block_id = p.block_id
  AND se.pool_name = p.pool_name
