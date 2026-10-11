# Airbnb Analytics with dbt

A dbt + Snowflake project that turns raw Airbnb data (listings, hosts, reviews) into clean, tested, documented models, and answers one question:

> **Are guest reviews more negative the day after a full moon?**

| | Negative reviews |
|---|---|
| Day after a full moon | **7.73%** (1,070 of 13,850) |
| Other days | **7.28%** |

Slightly higher (+0.45 pp), but a small effect, only about two standard errors.

## Tech stack
- **dbt Core 1.11** + dbt-snowflake
- **Snowflake**: warehouse, key-pair auth, separate roles for dbt (`TRANSFORM`) and BI (`REPORTER`)
- **dbt packages**: dbt_utils, dbt_expectations
- **Dagster**: orchestration (daily schedule)
- **GitHub Actions**: Slim CI on pull requests
- **uv**: Python dependencies

## Lineage
```
raw_listings → src_listings → dim_listings_cleansed ──────┐
raw_hosts    → src_hosts    → dim_hosts_cleansed (v1, v2) ─┴→ dim_listings_w_hosts ─┐
                                    └→ int_host_performance                        ├→ Executive Dashboard
raw_reviews  → src_reviews  → fct_reviews ──────────────→ mart_fullmoon_reviews ──┘     (exposure)
                              seed_full_moon_dates ─────┘
raw_listings / raw_hosts → scd_raw_listings / scd_raw_hosts (snapshots, SCD2)
```

## Layers
| Folder | Models | Materialization |
|---|---|---|
| `models/src/` | src_listings, src_hosts, src_reviews | ephemeral |
| `models/dim/` | dim_listings_cleansed, dim_hosts_cleansed (v1/v2, contract), dim_listings_w_hosts, dim_long_term_listings (Python), dim_fullmoon (Python) | view / table |
| `models/intermediate/` | int_host_performance | table |
| `models/fct/` | fct_reviews (surrogate key, backfill vars) | incremental |
| `models/mart/` | mart_fullmoon_reviews | microbatch incremental, schema `mart` |
| `snapshots/` | scd_raw_listings, scd_raw_hosts | SCD Type 2 |

## Quality
- Generic tests (unique, not_null, relationships, accepted_values), singular tests, custom generic tests (`positive_values`, `minimum_row_count`)
- A unit test for the full moon date logic
- A model contract + `not null` constraints on the hosts dimension
- dbt_expectations checks (row count vs source, price range), with a known price outlier reported as a warning
- Source freshness on reviews

## Run it
```sh
uv sync
source .venv/bin/activate
cd airbnb
dbt deps
dbt debug          # needs airbnb/profiles.yml (git-ignored) with your Snowflake connection
dbt build
dbt docs generate && dbt docs serve
```
With environment variables instead of a local profile:
```sh
. ../set-env.sh                       # exports SNOWFLAKE_ACCOUNT, DBT_USER, PRIVATE_KEY, PRIVATE_KEY_PASSPHRASE
export DBT_ENV_NAME=MYDEV             # personal dev schema
dbt build --profiles-dir _prod_profiles                  # dev
dbt build --profiles-dir _prod_profiles --target prod    # prod
```
Orchestration:
```sh
cd my_dbt_dagster_project && dagster dev    # http://localhost:3000
```
