{{ config(
  materialized = 'view'
) }}

SELECT
  tx_id,
  amount,
  new_bond_address,
  old_bond_address,
  node_address,
  memo,
  to_addr AS to_address,
  event_id,
  block_timestamp,
  DATEADD(
    ms,
    __HEVO__LOADED_AT,
    '1970-01-01'
  ) AS _INSERTED_TIMESTAMP
FROM
  {{ ref('bronze__rebond_events') }}
  qualify(ROW_NUMBER() over(PARTITION BY event_id, tx_id, new_bond_address, old_bond_address, node_address, block_timestamp
ORDER BY
  __HEVO__LOADED_AT DESC)) = 1
