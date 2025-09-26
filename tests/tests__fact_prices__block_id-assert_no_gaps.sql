{{ config(
    warn_if = "> 10",
    severity = "warn"
) }}
{{ sequence_distinct_gaps_dim_block_id(ref("price__fact_prices"), "block_id") }}
