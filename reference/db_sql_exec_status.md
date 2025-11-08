# Get SQL Query Status

Get SQL Query Status

## Usage

``` r
db_sql_exec_status(
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

This request can be used to poll for the statement's status. When the
`status.state` field is `SUCCEEDED` it will also return the result
manifest and the first chunk of the result data.

When the statement is in the terminal states `CANCELED`, `CLOSED` or
`FAILED`, it returns HTTP `200` with the state set.

After at least 12 hours in terminal state, the statement is removed from
the warehouse and further calls will receive an HTTP `404` response.

[Read more on Databricks API
docs](https://docs.databricks.com/api/workspace/statementexecution/getstatement)

## See also

Other SQL Execution APIs:
[`db_sql_exec_cancel()`](https://databrickslabs.github.io/brickster/reference/db_sql_exec_cancel.md),
[`db_sql_exec_query()`](https://databrickslabs.github.io/brickster/reference/db_sql_exec_query.md),
[`db_sql_exec_result()`](https://databrickslabs.github.io/brickster/reference/db_sql_exec_result.md)
