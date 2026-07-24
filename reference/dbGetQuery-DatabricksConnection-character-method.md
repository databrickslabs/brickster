# Execute SQL query and return results

Execute SQL query and return results

## Usage

``` r
# S4 method for class 'DatabricksConnection,character'
dbGetQuery(
  conn,
  statement,
  disposition = conn@disposition,
  show_progress = conn@show_progress,
  ...
)
```

## Arguments

- conn:

  A DatabricksConnection object

- statement:

  SQL statement to execute

- disposition:

  Query disposition mode. Defaults to the connection's `disposition`
  setting.

- show_progress:

  If `TRUE`, show progress updates during query execution. Defaults to
  the connection's `show_progress` setting.

- ...:

  Additional arguments passed to underlying query execution

## Value

A data.frame with query results
