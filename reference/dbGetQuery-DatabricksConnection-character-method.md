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
  ...,
  query_tags = conn@query_tags
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

- query_tags:

  Named list of execution-level query tags, as in
  [`db_sql_exec_query()`](https://databrickslabs.github.io/brickster/reference/db_sql_exec_query.md).
  Defaults to the connection's tags. An explicitly supplied list
  replaces all connection tags for this statement only; `NULL` or
  [`list()`](https://rdrr.io/r/base/list.html) omits tags for this
  statement.

## Value

A data.frame with query results

## See also

Other DBI Methods:
[`dbConnect,DatabricksDriver-method`](https://databrickslabs.github.io/brickster/reference/dbConnect-DatabricksDriver-method.md),
[`dbExecute,DatabricksConnection,character-method`](https://databrickslabs.github.io/brickster/reference/dbExecute-DatabricksConnection-character-method.md),
[`dbSendQuery,DatabricksConnection,character-method`](https://databrickslabs.github.io/brickster/reference/dbSendQuery-DatabricksConnection-character-method.md),
[`dbSendStatement,DatabricksConnection,character-method`](https://databrickslabs.github.io/brickster/reference/dbSendStatement-DatabricksConnection-character-method.md)
