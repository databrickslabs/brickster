# Fetch results from Databricks query

Fetch results from Databricks query

## Usage

``` r
# S4 method for class 'DatabricksResult'
dbFetch(res, n = -1, ...)
```

## Arguments

- res:

  A DatabricksResult object

- n:

  Maximum number of rows to fetch (-1 for all rows)

- ...:

  Additional arguments (ignored)

## Value

A data.frame with query results
