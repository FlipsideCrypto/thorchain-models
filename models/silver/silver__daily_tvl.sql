{{ config(
  materialized = 'incremental',
  unique_key = "day",
  incremental_strategy = 'merge',
  incremental_predicates = ["DBT_INTERNAL_DEST.day" >= datediff(day, -3, current_date)]  
) }}

WITH max_daily_block AS (

  SELECT
    MAX(block_id) AS block_id,
    DATE_TRUNC(
      'day',
      block_timestamp
    ) AS DAY
  FROM
    {{ ref('silver__prices') }}

{% if is_incremental() %}
WHERE
  block_timestamp :: DATE >= (
    SELECT
      MAX(
        DAY
      )
    FROM
      {{ this }}
  ) - INTERVAL '48 HOURS'
{% endif %}
GROUP BY
  DAY
),
daily_rune_price AS (
  SELECT
    p.block_id,
    DAY,
    AVG(rune_usd) AS rune_usd
  FROM
    {{ ref('silver__prices') }}
    p
    JOIN max_daily_block mdb
    ON p.block_id = mdb.block_id

{% if is_incremental() %}
WHERE
  block_timestamp :: DATE >= (
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
  p.block_id
)
SELECT
  br.day,
  total_value_pooled AS total_value_pooled,
  total_value_pooled * rune_usd AS total_value_pooled_usd,
  total_value_bonded AS total_value_bonded,
  total_value_bonded * rune_usd AS total_value_bonded_usd,
  total_value_locked AS total_value_locked,
  total_value_locked * rune_usd AS total_value_locked_usd
FROM
  {{ ref('silver__total_value_locked') }}
  br
  JOIN daily_rune_price drp
  ON br.day = drp.day
