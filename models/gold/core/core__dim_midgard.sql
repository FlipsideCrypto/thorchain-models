{{ config(
    materialized = 'view'
) }}

SELECT
    '2.26.0' AS midgard_version
