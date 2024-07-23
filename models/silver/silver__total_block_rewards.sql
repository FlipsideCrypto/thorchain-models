{{ config(
  materialized = 'incremental',
  unique_key = "_unique_key",
  incremental_strategy = 'merge',
  incremental_predicates = ["DBT_INTERNAL_DEST._inserted_timestamp" >= datediff(day, -3, current_date)],
  cluster_by = ['_inserted_timestamp::DATE']
) }}

WITH block_prices AS (

  SELECT
    AVG(rune_usd) AS rune_usd,
    block_id
  FROM
    {{ ref('silver__prices') }}
  GROUP BY
    block_id
),
fin AS (
  SELECT
    b.block_timestamp,
    b.height AS block_id,
    ree.pool_name AS reward_entity,
    COALESCE(rune_e8 / pow(10, 8), 0) AS rune_amount,
    COALESCE(rune_e8 / pow(10, 8) * rune_usd, 0) AS rune_amount_usd,
    concat_ws(
      '-',
      b.height,
      reward_entity
    ) AS _unique_key,
    ree._inserted_timestamp
  FROM
    {{ ref('silver__rewards_event_entries') }}
    ree
    JOIN {{ ref('silver__block_log') }}
    b
    ON ree.block_timestamp = b.timestamp
    LEFT JOIN {{ ref('silver__prices') }}
    p
    ON b.height = p.block_id
    AND ree.pool_name = p.pool_name

{% if is_incremental() %}
WHERE
  (
    ree._INSERTED_TIMESTAMP :: DATE >= (
      SELECT
        MAX(
          _INSERTED_TIMESTAMP
        )
      FROM
        {{ this }}
    ) - INTERVAL '48 HOURS'
    OR concat_ws(
      '-',
      b.height,
      reward_entity
    ) IN (
      SELECT
        _unique_key
      FROM
        {{ this }}
      WHERE
        rune_amount_USD IS NULL
    )
  )
{% endif %}
UNION
SELECT
  b.block_timestamp,
  b.height AS block_id,
  'bond_holders' AS reward_entity,
  bond_e8 / pow(
    10,
    8
  ) AS rune_amount,
  bond_e8 / pow(
    10,
    8
  ) * rune_usd AS rune_amount_usd,
  concat_ws(
    '-',
    b.height,
    reward_entity
  ) AS _unique_key,
  re._inserted_timestamp
FROM
  {{ ref('silver__rewards_events') }}
  re
  JOIN {{ ref('silver__block_log') }}
  b
  ON re.block_timestamp = b.timestamp
  LEFT JOIN block_prices p
  ON b.height = p.block_id

{% if is_incremental() %}
WHERE
  (
    re._INSERTED_TIMESTAMP :: DATE >= (
      SELECT
        MAX(
          _INSERTED_TIMESTAMP
        )
      FROM
        {{ this }}
    ) - INTERVAL '48 HOURS'
    OR concat_ws(
      '-',
      b.height,
      reward_entity
    ) IN (
      SELECT
        _unique_key
      FROM
        {{ this }}
      WHERE
        rune_amount_USD IS NULL
    )
  )
{% endif %}
)
SELECT
  block_timestamp,
  block_id,
  reward_entity,
  SUM(
    rune_amount
  ) AS rune_amount,
  SUM(rune_amount_usd) AS rune_amount_usd,
  _unique_key,
  MAX(_inserted_timestamp) AS _inserted_timestamp
FROM
  fin
GROUP BY
  block_timestamp,
  block_id,
  reward_entity,
  _unique_key
