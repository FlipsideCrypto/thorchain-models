{{ config(
    materialized = 'view'
) }}

SELECT
    '2.32.9' AS midgard_version
