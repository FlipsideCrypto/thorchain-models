{{ config(
    materialized = 'view'
) }}

SELECT
    '2.24.2' AS midgard_version
