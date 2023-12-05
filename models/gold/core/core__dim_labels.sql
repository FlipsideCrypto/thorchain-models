{{ config(
    materialized = 'table'
) }}

SELECT
    {{ dbt_utils.generate_surrogate_key(
        [' address ']
    ) }} AS dim_labels_id,
    blockchain,
    creator,
    address,
    label_type,
    label_subtype,
    project_name AS label,
    address_name AS address_name,
    '{{ invocation_id }}' AS _audit_run_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp
FROM
    {{ ref('silver__croschain_labels') }}
