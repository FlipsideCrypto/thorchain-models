{{ config(
    materialized = 'view'
) }}

SELECT
    '2.29.0' AS midgard_version
