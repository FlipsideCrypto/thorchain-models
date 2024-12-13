{{ config(
    materialized = 'view'
) }}

SELECT
    '2.28.1' AS midgard_version
