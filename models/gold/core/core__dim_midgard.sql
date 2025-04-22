{{ config(
    materialized = 'view'
) }}

SELECT
    '2.31.0' AS midgard_version
