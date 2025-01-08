{{ config(
  materialized = 'view'
) }}

WITH base AS (
  SELECT 
    tx_id,
    blockchain,
    block_timestamp,
    pool_name,
    affiliate_addresses_array,
    affiliate_fee_basis_points_array,
    _inserted_timestamp
  FROM {{ ref('silver__swaps') }}
  WHERE array_size(affiliate_addresses_array) > 0
),
exploded AS (
  SELECT 
    tx_id,
    blockchain,
    block_timestamp,
    pool_name,
    f.value::string as affiliate_address,
    b.value::integer as affiliate_fee_basis_points,
    _inserted_timestamp,
    f.index as affiliate_index,
    concat_ws('-', tx_id, f.value::string) as _unique_key
  FROM base,
  LATERAL FLATTEN(input => affiliate_addresses_array) f,
  LATERAL FLATTEN(input => affiliate_fee_basis_points_array) b
  WHERE f.index = b.index
)
SELECT 
  tx_id,
  blockchain,
  block_timestamp,
  pool_name,
  affiliate_address,
  affiliate_fee_basis_points,
  _inserted_timestamp,
  affiliate_index,
  _unique_key
FROM exploded
