{{ config(
  materialized = 'view'
) }}

SELECT
  rune_price_e8,
  block_timestamp,
  DATEADD(
    ms,
    __HEVO__LOADED_AT,
    '1970-01-01'
  ) AS _INSERTED_TIMESTAMP
FROM
  {{ ref(
    'bronze__rune_price'
  ) }}
QUALIFY(
  ROW_NUMBER() OVER (
    PARTITION BY block_timestamp
    ORDER BY __HEVO__LOADED_AT DESC
  ) = 1
)