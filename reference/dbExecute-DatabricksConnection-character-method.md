# Execute statement on Databricks

Execute statement on Databricks

## Usage

``` r
# S4 method for class 'DatabricksConnection,character'
dbExecute(conn, statement, ..., query_tags = conn@query_tags)
```

## Arguments

- conn:

  A DatabricksConnection object

- statement:

  SQL statement

- ...:

  Additional arguments (ignored)

- query_tags:

  Named list of execution-level query tags, as in
  [`db_sql_exec_query()`](https://databrickslabs.github.io/brickster/reference/db_sql_exec_query.md).
  Defaults to the connection's tags. An explicitly supplied list
  replaces all connection tags for this statement only; `NULL` or
  [`list()`](https://rdrr.io/r/base/list.html) omits tags for this
  statement.

## Value

Number of rows in result set (from metadata, without loading data)

## See also

Other DBI Methods:
[`dbConnect,DatabricksDriver-method`](https://databrickslabs.github.io/brickster/reference/dbConnect-DatabricksDriver-method.md),
[`dbGetQuery,DatabricksConnection,character-method`](https://databrickslabs.github.io/brickster/reference/dbGetQuery-DatabricksConnection-character-method.md),
[`dbSendQuery,DatabricksConnection,character-method`](https://databrickslabs.github.io/brickster/reference/dbSendQuery-DatabricksConnection-character-method.md),
[`dbSendStatement,DatabricksConnection,character-method`](https://databrickslabs.github.io/brickster/reference/dbSendStatement-DatabricksConnection-character-method.md)
