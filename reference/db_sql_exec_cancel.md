# Cancel SQL Query

Cancel SQL Query

## Usage

``` r
db_sql_exec_cancel(
  statement_id,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

- statement_id:

  String, query execution `statement_id`

- host:

  Databricks workspace URL, defaults to calling
  [`db_host()`](https://databrickslabs.github.io/brickster/reference/db_host.md).

- token:

  Databricks workspace token, defaults to calling
  [`db_token()`](https://databrickslabs.github.io/brickster/reference/db_token.md).

- perform_request:

  If `TRUE` (default) the request is performed, if `FALSE` the httr2
  request is returned *without* being performed.

## Details

Requests that an executing statement be canceled. Callers must poll for
status to see the terminal state.

[Read more on Databricks API
docs](https://docs.databricks.com/api/workspace/statementexecution/cancelexecution)

## See also

Other SQL Execution APIs:
[`db_sql_exec_query()`](https://databrickslabs.github.io/brickster/reference/db_sql_exec_query.md),
[`db_sql_exec_result()`](https://databrickslabs.github.io/brickster/reference/db_sql_exec_result.md),
[`db_sql_exec_status()`](https://databrickslabs.github.io/brickster/reference/db_sql_exec_status.md)
