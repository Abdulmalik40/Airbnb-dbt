# Airbnb Analytics with dbt

A dbt + Snowflake project that turns raw Airbnb data (listings, hosts, reviews) into clean, tested, documented models, and answers one question:

> **Are guest reviews more negative the day after a full moon?**

| | Negative reviews |
|---|---|
| Day after a full moon | **7.73%** (1,070 of 13,850) |
| Other days | **7.28%** |

Slightly higher (+0.45 pp), but a small effect.

**How it was measured:** every review is tagged `positive`, `neutral` or `negative` in the raw data. `mart_fullmoon_reviews` joins each review to the full moon calendar (`seed_full_moon_dates`) and flags reviews written the day **after** a full moon, since that night's sleep is what a guest would complain about. `analyses/full_moon_no_sleep.sql` then counts sentiment per group. The +0.45 pp gap is about two standard errors (SE ≈ 0.23 pp), so it is only borderline significant: an interesting signal, not proof.

## Data
[Inside Airbnb](https://insideairbnb.com/) data for Berlin: about 17.5k listings, 14k hosts and 410k reviews, loaded as-is into `AIRBNB.RAW`.

<details>
<summary>Load the raw tables into Snowflake</summary>

```sql
CREATE DATABASE IF NOT EXISTS AIRBNB;
CREATE SCHEMA IF NOT EXISTS AIRBNB.RAW;
USE SCHEMA AIRBNB.RAW;

CREATE OR REPLACE TABLE raw_listings (id integer, listing_url string, name string, room_type string,
    minimum_nights integer, host_id integer, price string, created_at datetime, updated_at datetime);
CREATE OR REPLACE TABLE raw_reviews (listing_id integer, date datetime, reviewer_name string,
    comments string, sentiment string);
CREATE OR REPLACE TABLE raw_hosts (id integer, name string, is_superhost string,
    created_at datetime, updated_at datetime);

COPY INTO raw_listings FROM 's3://dbt-datasets/listings.csv'
    FILE_FORMAT = (type = 'CSV' skip_header = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"');
COPY INTO raw_reviews FROM 's3://dbt-datasets/reviews.csv'
    FILE_FORMAT = (type = 'CSV' skip_header = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"');
COPY INTO raw_hosts FROM 's3://dbt-datasets/hosts.csv'
    FILE_FORMAT = (type = 'CSV' skip_header = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"');
```
</details>

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
raw_reviews  → src_reviews  → fct_reviews ──────────────→ mart_fullmoon_reviews ──┘     (exposure, planned)
                              seed_full_moon_dates ─────┘
dim_listings_cleansed → dim_long_term_listings (Python)
seed_full_moon_dates  → dim_fullmoon (Python)
raw_listings / raw_hosts → scd_raw_listings / scd_raw_hosts (snapshots, SCD2)
```
The Executive Dashboard is declared as a dbt exposure; the BI dashboard itself is not built yet.

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
export SNOWFLAKE_ACCOUNT=<account-identifier>
export DBT_USER=<snowflake-user>
export PRIVATE_KEY="$(cat path/to/rsa_key.p8)"
export PRIVATE_KEY_PASSPHRASE=<key-passphrase>
export DBT_ENV_NAME=MYDEV             # personal dev schema
dbt build --profiles-dir _prod_profiles                  # dev
dbt build --profiles-dir _prod_profiles --target prod    # prod
```
Orchestration:
```sh
cd ../my_dbt_dagster_project && dagster dev    # http://localhost:3000
```
