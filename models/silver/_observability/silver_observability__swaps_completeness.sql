{{ config(
    materialized = 'incremental',
    unique_key = 'test_timestamp',
    full_refresh = false,
    tags = ['observability']
) }}

WITH summary_stats AS (

    SELECT
      MIN(height) AS min_block,
      MAX(height) AS max_block,
      MIN(block_timestamp) AS min_block_timestamp,
      MAX(block_timestamp) AS max_block_timestamp,
      COUNT(1) AS blocks_tested
    FROM {{ ref('silver__block_log') }}
    WHERE block_timestamp <= DATEADD('hour', -12, CURRENT_TIMESTAMP())


{% if is_incremental() %}
AND (block_number >= (SELECT MIN(block_number) 
                      FROM ( SELECT MIN(height) AS block_number 
                             FROM {{ ref('silver__block_log') }} 
                             WHERE block_timestamp BETWEEN DATEADD('hour', -96, CURRENT_TIMESTAMP())
                               AND DATEADD('hour', -95, CURRENT_TIMESTAMP())
                             
                             UNION
                             
                             SELECT MIN(VALUE) - 1 AS block_number
                             FROM(SELECT blocks_impacted_array 
                                  FROM {{ this }} qualify ROW_NUMBER() over (ORDER BY test_timestamp DESC) = 1),
                                       LATERAL FLATTEN(input => blocks_impacted_array)
                            )
                      ) {% if var('OBSERV_FULL_TEST') %}
            OR block_number >= 0
    {% endif %}
    )
{% endif %}

),

block_range AS (

    SELECT
      _id AS block_number
    FROM {{ source( 'crosschain_silver', 'number_sequence' ) }}
    WHERE _id BETWEEN ( SELECT min_block FROM summary_stats)
      AND (SELECT max_block FROM summary_stats)

),

broken_blocks AS (

    SELECT 
      DISTINCT height as block_number
    FROM {{ ref("silver__block_log") }} b
        
    LEFT JOIN {{ ref("silver__swaps") }} t 
      ON b.height = t.block_id
    
    JOIN block_range br
      ON b.height = br.block_number
      AND t.block_id = br.block_number
    
    WHERE t.tx_id IS NULL

),

impacted_blocks AS (

    SELECT
      COUNT(1) AS blocks_impacted_count,
      ARRAY_AGG(block_number) within GROUP (ORDER BY block_number ) AS blocks_impacted_array
    FROM broken_blocks

)

SELECT
  'transactions' AS test_name,
  min_block,
  max_block,
  min_block_timestamp,
  max_block_timestamp,
  blocks_tested,
  blocks_impacted_count,
  blocks_impacted_array,
  CURRENT_TIMESTAMP() AS test_timestamp
FROM summary_stats

JOIN impacted_blocks
  ON 1 = 1