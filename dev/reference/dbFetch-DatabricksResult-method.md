# Fetch results from Databricks query

Fetch results from Databricks query

## Usage

``` r
# S4 method for class 'DatabricksResult'
dbFetch(res, n = -1, show_progress = res@connection@show_progress, ...)
```

## Arguments

- res:

  A DatabricksResult object

- n:

  Maximum number of rows to fetch (-1 for all rows)

- show_progress:

  If `TRUE`, show progress updates during result fetching. Defaults to
  the connection's `show_progress` setting.

- ...:

  Additional arguments (ignored)

## Value

A data.frame with query results
