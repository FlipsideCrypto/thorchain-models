{{ config(
  materialized = 'incremental',
  unique_key = "_unique_key",
  incremental_strategy = 'merge',
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
)
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
  ree._INSERTED_TIMESTAMP :: DATE >= (
    SELECT
      MAX(
        _INSERTED_TIMESTAMP
      )
    FROM
      {{ this }}
  ) - INTERVAL '4 HOURS'
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
  re._INSERTED_TIMESTAMP :: DATE >= (
    SELECT
      MAX(
        _INSERTED_TIMESTAMP
      )
    FROM
      {{ this }}
  ) - INTERVAL '4 HOURS'
{% endif %}
