{{ config(
    materialized = 'view',
    persist_docs ={ "relation": true,
    "columns": true }
) }}

SELECT
    HOUR,
    NULL AS token_address,
    symbol,
    NAME,
    decimals,
    price,
    blockchain,
    TRUE AS is_native,
    is_deprecated,
    is_imputed,
    inserted_timestamp,
    modified_timestamp,
    complete_native_prices_id AS ez_prices_hourly_id
FROM
    {{ ref('silver__complete_native_prices') }}
