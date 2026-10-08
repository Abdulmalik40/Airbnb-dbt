# Airbnb Analytics with dbt

A dbt + Snowflake project that turns raw Airbnb data (listings, hosts, reviews) into clean, tested models ready for analysis.

## Tech stack
- **dbt Core** with the Snowflake adapter
- **Snowflake** as the data warehouse
- **uv** to manage Python dependencies

## Project layout
```
airbnb/            dbt project
  models/src/      source-layer models built on the raw tables
```

## Getting started
```sh
uv sync
source .venv/bin/activate
cd airbnb
dbt debug   # needs a profiles.yml with your Snowflake connection
dbt run
```
