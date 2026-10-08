# airbnb dbt project

dbt models that transform raw Airbnb data (listings, hosts, reviews) in Snowflake.

## Structure
- `models/src/` – source-layer models that clean and rename the raw tables

## Usage
```sh
dbt run
dbt test
```
