{{ config(
    materialized = 'view'
) }}

SELECT
    '2.33.0' AS midgard_version
