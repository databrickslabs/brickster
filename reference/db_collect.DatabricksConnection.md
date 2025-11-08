# Collect query results with proper progress timing for Databricks

Collect query results with proper progress timing for Databricks

## Usage

``` r
# S3 method for class 'DatabricksConnection'
db_collect(con, sql, n = -1, warn_incomplete = TRUE, ...)
```

## Arguments

- con:

  A DatabricksConnection object

- sql:

  SQL query to execute

- n:

  Maximum number of rows to collect (-1 for all)

- warn_incomplete:

  Whether to warn if results were truncated

- ...:

  Additional arguments

## Value

A data frame with query results
