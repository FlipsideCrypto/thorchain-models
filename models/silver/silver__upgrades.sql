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
  tx_id,
  from_address,
  to_address,
  burn_asset,
  burn_e8 / pow(
    10,
    8
  ) AS rune_amount,
  burn_e8 / pow(
    10,
    8
  ) * rune_usd AS rune_amount_usd,
  mint_e8 / pow(
    10,
    8
  ) AS mint_amount,
  mint_e8 / pow(
    10,
    8
  ) * rune_usd AS mint_amount_usd,
  concat_ws(
    '-',
    tx_id,
    se.block_timestamp,
    from_address,
    to_address,
    burn_asset
  ) AS _unique_key,
  se._inserted_timestamp
FROM
  {{ ref('silver__switch_events') }}
  se
  JOIN {{ ref('silver__block_log') }}
  b
  ON se.block_timestamp = b.timestamp
  LEFT JOIN block_prices p
  ON b.height = p.block_id

{% if is_incremental() %}
WHERE
  se._inserted_timestamp >= (
    SELECT
      MAX(
        _inserted_timestamp
      )
    FROM
      {{ this }}
  ) 
{% endif %}
