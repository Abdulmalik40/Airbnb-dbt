{% macro drop_dev_schemas() %}
  {#- Drops the target schema and its custom schemas (<schema>_mart, <schema>__test_failures, ...). Never runs on prod. -#}
  {% if target.name == 'prod' %}
    {{ exceptions.raise_compiler_error("drop_dev_schemas must not run against prod") }}
  {% endif %}
  {% set q %}
    SELECT schema_name
    FROM {{ target.database }}.information_schema.schemata
    WHERE schema_name = UPPER('{{ target.schema }}')
       OR STARTSWITH(schema_name, UPPER('{{ target.schema }}') || '_')
  {% endset %}
  {% if execute %}
    {% for s in run_query(q).columns[0].values() %}
      {% do log('Dropping schema ' ~ s, info=True) %}
      {% do run_query('DROP SCHEMA IF EXISTS ' ~ target.database ~ '.' ~ s ~ ' CASCADE') %}
    {% endfor %}
  {% endif %}
{% endmacro %}
