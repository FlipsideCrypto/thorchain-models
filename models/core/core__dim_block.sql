{{ config(
    materialized = 'incremental',
    unique_key = 'dim_block_id',
    incremental_strategy = 'merge',
    cluster_by = ['block_timestamp::DATE']
) }}

SELECT
    {{ dbt_utils.surrogate_key(
        ['height']
    ) }} AS dim_block_id,
    height AS block_id,
    block_timestamp,
    block_date,
    block_hour,
    block_week,
    block_month,
    block_quarter,
    block_year,
    block_DAYOFMONTH,
    block_DAYOFWEEK,
    block_DAYOFYEAR,
    TIMESTAMP,
    HASH,
    agg_state,
    _INSERTED_TIMESTAMP,
    '{{ env_var("DBT_CLOUD_RUN_ID", "manual") }}' AS _audit_run_id
FROM
    {{ ref('silver__block_log') }}

{% if is_incremental() %}
WHERE
    _inserted_timestamp >= (
        SELECT
            MAX(
                _inserted_timestamp
            )
        FROM
            {{ this }}
    ) - INTERVAL '48 HOURS'
{% endif %}
UNION ALL
SELECT
    '-1' AS dim_block_id,
    -1 AS block_id,
    '1900-01-01' :: datetime AS block_timestamp,
    NULL AS block_date,
    NULL AS block_hour,
    NULL AS block_week,
    NULL AS block_month,
    NULL AS block_quarter,
    NULL AS block_year,
    NULL AS block_DAYOFMONTH,
    NULL AS block_DAYOFWEEK,
    NULL AS block_DAYOFYEAR,
    NULL AS TIMESTAMP,
    NULL AS HASH,
    NULL AS agg_state,
    '1900-01-01' :: DATE AS _inserted_timestamp,
    '{{ env_var("DBT_CLOUD_RUN_ID", "manual") }}' AS _audit_run_id
UNION ALL
SELECT
    '-2' AS dim_block_id,
    -2 AS block_id,
    NULL AS block_timestamp,
    NULL AS block_date,
    NULL AS block_hour,
    NULL AS block_week,
    NULL AS block_month,
    NULL AS block_quarter,
    NULL AS block_year,
    NULL AS block_DAYOFMONTH,
    NULL AS block_DAYOFWEEK,
    NULL AS block_DAYOFYEAR,
    NULL AS TIMESTAMP,
    NULL AS HASH,
    NULL AS agg_state,
    '1900-01-01' :: DATE AS _inserted_timestamp,
    '{{ env_var("DBT_CLOUD_RUN_ID", "manual") }}' AS _audit_run_id
