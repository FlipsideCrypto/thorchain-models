{{ config(
  materialized = 'incremental',
  unique_key = "day",
  incremental_strategy = 'merge',
  cluster_by = ['day']
) }}

WITH bond_type_day AS (

  SELECT
    DATE(
      b.block_timestamp
    ) AS DAY,
    bond_type,
    (SUM(e8) / pow(10, 8)) AS rune_amount,
    MAX(
      A._inserted_timestamp
    ) AS _inserted_timestamp
  FROM
    {{ ref('silver__bond_events') }} A
    JOIN {{ ref('silver__block_log') }}
    b
    ON A.block_timestamp = b.timestamp

{% if is_incremental() %}
WHERE
  b.block_timestamp :: DATE >= (
    SELECT
      MAX(
        DAY - INTERVAL '2 DAYS' --counteract clock skew
      )
    FROM
      {{ this }}
  ) 
{% endif %}
GROUP BY
  DAY,
  bond_type
),
bond_type_day_direction AS (
  SELECT
    DAY,
    bond_type,
    CASE
      WHEN bond_type IN (
        'bond_returned',
        'bond_cost'
      ) THEN -1
      ELSE 1
    END AS direction,
    rune_amount,
    rune_amount * direction AS abs_rune_amount,
    _inserted_timestamp
  FROM
    bond_type_day
),
total_value_bonded_tbl AS (
  SELECT
    DAY,
    SUM(abs_rune_amount) AS total_value_bonded,
    MAX(_inserted_timestamp) AS _inserted_timestamp
  FROM
    bond_type_day_direction
  GROUP BY
    DAY
),
total_pool_depth AS (
  SELECT
    DATE(
      b.block_timestamp
    ) AS DAY,
    b.height AS block_id,
    pool_name,
    rune_e8,
    asset_e8,
    MAX(height) over (PARTITION BY pool_name, DATE(b.block_timestamp)) AS max_block_id,
    A._inserted_timestamp
  FROM
    {{ ref('silver__block_pool_depths') }} A
    JOIN {{ ref('silver__block_log') }}
    b
    ON A.block_timestamp = b.timestamp
  WHERE LOWER(pool_name) NOT LIKE 'thor.%'

{% if is_incremental() %}
AND
  b.block_timestamp :: DATE >= (
    SELECT
      MAX(
        DAY - INTERVAL '2 DAYS' --counteract clock skew
      )
    FROM
      {{ this }}
  ) 
{% endif %}
),
total_pool_depth_max AS (
  SELECT
    DAY,
    rune_e8 AS rune_depth,
    asset_e8 AS asset_depth,
    _inserted_timestamp
  FROM
    total_pool_depth
  WHERE
    block_id = max_block_id
),
total_value_pooled_tbl AS (
  SELECT
    DAY,
    SUM(rune_depth) * 2 / power(
      10,
      8
    ) AS total_value_pooled,
    MAX(_inserted_timestamp) AS _inserted_timestamp
  FROM
    total_pool_depth_max
  GROUP BY
    DAY
)
SELECT
  COALESCE(
    total_value_bonded_tbl.day,
    total_value_pooled_tbl.day
  ) AS DAY,
  COALESCE(
    total_value_pooled,
    0
  ) AS total_value_pooled,
  COALESCE(SUM(total_value_bonded) over (
ORDER BY
  COALESCE(total_value_bonded_tbl.day, total_value_pooled_tbl.day) ASC), 0) AS total_value_bonded,
  COALESCE(
    total_value_pooled,
    0
  ) + SUM(COALESCE(total_value_bonded, 0)) over (
    ORDER BY
      COALESCE(
        total_value_bonded_tbl.day,
        total_value_pooled_tbl.day
      ) ASC
  ) AS total_value_locked,
  total_value_bonded_tbl._inserted_timestamp
FROM
  total_value_bonded_tbl full
  JOIN total_value_pooled_tbl
  ON total_value_bonded_tbl.day = total_value_pooled_tbl.day
