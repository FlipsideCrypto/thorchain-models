{{ config(
    materialized = 'view'
) }}

SELECT
    '2.34.0' AS midgard_version
