# airbnb dbt project

dbt models that transform raw Airbnb data (listings, hosts, reviews) in Snowflake.
See the [main README](../README.md) for the full overview.

## Structure
- `models/src/`: staging models over the raw tables (ephemeral)
- `models/dim/`: cleansed dimensions, versioned hosts dimension, Python models
- `models/intermediate/`: host-level performance metrics
- `models/fct/`: incremental reviews fact
- `models/mart/`: full moon analysis mart (microbatch)
- `snapshots/`: SCD2 history of listings and hosts
- `tests/`: singular and custom generic tests
- `macros/`: reusable macros, schema naming, dev schema cleanup
- `analyses/`: the full moon sentiment analysis

## Usage
```sh
dbt deps
dbt build
```
