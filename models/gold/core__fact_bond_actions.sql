{{ config(
  materialized = 'incremental',
  meta ={ 'database_tags':{ 'table':{ 'PURPOSE': 'DEX, AMM' }}},
  unique_key = "fact_bond_actions_id",
  incremental_strategy = 'merge',
  cluster_by = ['block_timestamp::DATE']
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
bond_events AS (
  SELECT
    block_timestamp,
    tx_id,
    from_address,
    to_address,
    asset,
    blockchain,
    bond_type,
    asset_e8,
    e8,
    memo,
    event_id,
    _inserted_timestamp
  FROM
    {{ ref('silver__bond_events') }}

{% if is_incremental() %}
WHERE
  _inserted_timestamp >= (
    SELECT
      MAX(
        _inserted_timestamp
      )
    FROM
      {{ this }}
  ) - INTERVAL '4 HOURS'
  OR tx_id IN (
    SELECT
      tx_id
    FROM
      {{ this }}
    WHERE
      dim_block_id = '-1'
  )
{% endif %}
)
SELECT
  {{ dbt_utils.generate_surrogate_key(
    ['be.tx_id','be.from_address','be.to_address ','be.asset_e8','be.bond_type','be.e8','be.block_timestamp','be.blockchain','be.asset','be.memo']
  ) }} AS fact_bond_actions_id,
  b.block_timestamp,
  COALESCE(
    b.dim_block_id,
    '-1'
  ) AS dim_block_id,
  tx_id,
  from_address,
  to_address,
  asset,
  blockchain,
  bond_type,
  COALESCE(e8 / pow(10, 8), 0) AS asset_amount,
  COALESCE(
    rune_usd * asset_e8,
    0
  ) AS asset_usd,
  memo,
  be._inserted_timestamp,
  '{{ env_var("DBT_CLOUD_RUN_ID", "manual") }}' AS _audit_run_id
FROM
  bond_events be
  LEFT JOIN {{ ref('core__dim_block') }}
  b
  ON be.block_timestamp = b.timestamp
  LEFT JOIN block_prices p
  ON b.block_id = p.block_id
