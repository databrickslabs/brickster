# SQL Query Fields for Databricks connections

Generate SQL for field discovery queries optimized for Databricks. This
method generates appropriate SQL for discovering table fields.

## Usage

``` r
# S3 method for class 'DatabricksConnection'
sql_query_fields(con, sql, ...)
```

## Arguments

- con:

  DatabricksConnection object

- sql:

  SQL query to discover fields for

- ...:

  Additional arguments passed to other methods

## Value

SQL object for field discovery
