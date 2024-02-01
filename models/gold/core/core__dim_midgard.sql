{{ config(
    materialized = 'view'
) }}

SELECT
    '2.17.0' AS midgard_version
