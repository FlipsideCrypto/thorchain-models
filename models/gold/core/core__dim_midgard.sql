{{ config(
    materialized = 'view'
) }}

SELECT
    '2.25.1' AS midgard_version
