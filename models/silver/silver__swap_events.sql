{{ config(
  materialized = 'view'
) }}

WITH deduped AS (

  SELECT
    tx AS tx_id,
    chain AS blockchain,
    from_addr AS from_address,
    to_addr AS to_address,
    from_asset,
    from_e8,
    to_asset,
    to_e8,
    memo,
    pool AS pool_name,
    to_e8_min,
    swap_slip_bp,
    liq_fee_e8,
    liq_fee_in_rune_e8,
    _DIRECTION,
    event_id,
    block_timestamp,
    streaming_count,
    streaming_quantity,
    _STREAMING,
    _TX_TYPE,
    DATEADD(
      ms,
      __HEVO__LOADED_AT,
      '1970-01-01'
    ) AS _INSERTED_TIMESTAMP
  FROM
    {{ ref('bronze__swap_events') }}
    qualify(ROW_NUMBER() over(PARTITION BY event_id, tx, chain, to_addr, from_addr, from_asset, from_e8, to_asset, to_e8, memo, pool, _direction
  ORDER BY
    __HEVO__INGESTED_AT DESC)) = 1
),
streaming_stats AS (
  SELECT
    tx_id,
    COUNT(*) AS actual_streaming_count,
    MAX(CAST(streaming_count AS INTEGER)) AS max_streaming_count
  FROM
    deduped
  WHERE
    _STREAMING = TRUE
  GROUP BY
    tx_id
)
SELECT
  d.tx_id,
  d.blockchain,
  d.from_address,
  d.to_address,
  d.from_asset,
  d.from_e8,
  d.to_asset,
  d.to_e8,
  d.memo,
  d.pool_name,
  d.to_e8_min,
  d.swap_slip_bp,
  d.liq_fee_e8,
  d.liq_fee_in_rune_e8,
  d._DIRECTION,
  d.event_id,
  d.block_timestamp,
  d.streaming_count,
  -- WORKAROUND: Compute streaming_quantity from actual event count
  -- Use MAX(streaming_count) if it's > 1 (indicating it's working),
  -- otherwise use actual event count per transaction
  CASE
    WHEN d._STREAMING = TRUE
    AND ss.tx_id IS NOT NULL THEN CASE
      WHEN ss.max_streaming_count > 1 THEN ss.max_streaming_count
      ELSE ss.actual_streaming_count
    END
    ELSE CAST(
      d.streaming_quantity AS INTEGER
    )
  END AS streaming_quantity,
  d._STREAMING,
  d._TX_TYPE,
  d._INSERTED_TIMESTAMP
FROM
  deduped d
  LEFT JOIN streaming_stats ss
  ON d.tx_id = ss.tx_id
