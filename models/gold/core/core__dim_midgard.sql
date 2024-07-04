{{ config(
    materialized = 'view'
) }}

SELECT
    '2.22.3' AS midgard_version
