# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a dbt (data build tool) project for THORChain blockchain analytics, using Snowflake as the data warehouse. It transforms raw THORChain Midgard data into curated analytics tables covering swaps, liquidity, governance, and pricing.

## Common Commands

```bash
# Install dependencies
pip install -r requirements.txt
dbt deps

# Run all models
dbt run -s "thorchain_models,./models"

# Run a specific model
dbt run -s silver__swap_events

# Run tests
dbt test -m "thorchain_models,models/bronze" "thorchain_models,models/silver" "thorchain_models,models/gold"

# Run a single test
dbt test -s tests__fact_block_pool_depths__block_id_assert_no_gaps

# Compile SQL without running
dbt compile -s <model_name>
```

## Architecture

### Data Layer Pattern (Bronze → Silver → Gold)

- **Bronze** (`models/bronze/`): Raw views over source tables from Midgard (HEVO ingestion). Minimal transformation, direct mapping from `source('thorchain_midgard', 'midgard_*')`.
- **Silver** (`models/silver/`): Cleaned and standardized models. Renames columns to business terms (e.g., `tx` → `tx_id`, `chain` → `blockchain`), adds deduplication via `qualify ROW_NUMBER()`, and converts timestamps.
- **Gold** (`models/gold/`): Final analytics tables organized by domain:
  - `core/`: Dimension tables (blocks, labels)
  - `defi/`: DeFi facts (swaps, liquidity, pools, rewards, TVL)
  - `gov/`: Governance facts (nodes, validators, slashing)
  - `price/`: Asset pricing and metadata

### Data Sources

Source data comes from THORChain's Midgard indexer, loaded via Hevo into `HEVO.THORCHAIN_MIDGARD_METAL`. Cross-chain labels come from a separate `crosschain` database.

### Key Patterns

**Incremental models**: Gold fact tables use `incremental` materialization with `merge` strategy and 7-day lookback windows:
```sql
{% if is_incremental() %}
WHERE b.block_timestamp >= (SELECT MAX(block_timestamp - INTERVAL '7 days') FROM {{ this }})
{% endif %}
```

**Surrogate keys**: Generated using `dbt_utils.generate_surrogate_key()` on composite columns.

**Snowflake tags**: Models can have metadata tags applied via the `meta` config. Tags are pushed on each run unless disabled with `--var '{"UPDATE_SNOWFLAKE_TAGS":False}'`.

## Testing

Custom test macros in `macros/tests/`:
- `sequence_gaps`: Checks for gaps in sequential columns (block_id, day)
- `date_gaps`: Validates date continuity
- `sequence_distinct_gaps`: Gaps across distinct partitions

Tests in `tests/` directory verify data completeness (no gaps in block IDs, days).

## dbt Profile

The project uses the `thorchain` profile targeting Snowflake. See `profiles.yml` for template. Target database is `THORCHAIN_DEV` (dev) or `THORCHAIN` (prod).
