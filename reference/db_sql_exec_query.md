# Execute SQL Query

Execute SQL Query

## Usage

``` r
db_sql_exec_query(
  statement,
  warehouse_id,
  catalog = NULL,
  schema = NULL,
  parameters = NULL,
  row_limit = NULL,
  byte_limit = NULL,
  disposition = c("INLINE", "EXTERNAL_LINKS"),
  format = c("JSON_ARRAY", "ARROW_STREAM", "CSV"),
  wait_timeout = "0s",
  on_wait_timeout = c("CONTINUE", "CANCEL"),
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

- statement:

  String, the SQL statement to execute. The statement can optionally be
  parameterized, see `parameters`.

- warehouse_id:

  String, ID of warehouse upon which to execute a statement.

- catalog:

  String, sets default catalog for statement execution, similar to
  `USE CATALOG` in SQL.

- schema:

  String, sets default schema for statement execution, similar to
  `USE SCHEMA` in SQL.

- parameters:

  List of Named Lists, parameters to pass into a SQL statement
  containing parameter markers.

  A parameter consists of a name, a value, and *optionally* a type. To
  represent a `NULL` value, the value field may be omitted or set to
  `NULL` explicitly.

  See
  [docs](https://docs.databricks.com/api/workspace/statementexecution/executestatement)
  for more details.

- row_limit:

  Integer, applies the given row limit to the statement's result set,
  but unlike the `LIMIT` clause in SQL, it also sets the `truncated`
  field in the response to indicate whether the result was trimmed due
  to the limit or not.

- byte_limit:

  Integer, applies the given byte limit to the statement's result size.
  Byte counts are based on internal data representations and might not
  match the final size in the requested format. If the result was
  truncated due to the byte limit, then `truncated` in the response is
  set to true. When using `EXTERNAL_LINKS` disposition, a default
  byte_limit of 100 GiB is applied if `byte_limit` is not explicitly
  set.

- disposition:

  One of `"INLINE"` (default) or `"EXTERNAL_LINKS"`. See
  [docs](https://docs.databricks.com/api/workspace/statementexecution/executestatement)
  for details.

- format:

  One of `"JSON_ARRAY"` (default), `"ARROW_STREAM"`, or `"CSV"`. See
  [docs](https://docs.databricks.com/api/workspace/statementexecution/executestatement)
  for details.

- wait_timeout:

  String, default is `"10s"`. The time in seconds the call will wait for
  the statement's result set as `Ns`, where `N` can be set to `0` or to
  a value between `5` and `50`. When set to `0s`, the statement will
  execute in asynchronous mode and the call will not wait for the
  execution to finish. In this case, the call returns directly with
  `PENDING` state and a statement ID which can be used for polling with
  [`db_sql_exec_status()`](https://databrickslabs.github.io/brickster/reference/db_sql_exec_status.md).

  When set between `5` and `50` seconds, the call will behave
  synchronously up to this timeout and wait for the statement execution
  to finish. If the execution finishes within this time, the call
  returns immediately with a manifest and result data (or a `FAILED`
  state in case of an execution error).

  If the statement takes longer to execute, `on_wait_timeout` determines
  what should happen after the timeout is reached.

- on_wait_timeout:

  One of `"CONTINUE"` (default) or `"CANCEL"`. When `wait_timeout` \>
  `0s`, the call will block up to the specified time. If the statement
  execution doesn't finish within this time, `on_wait_timeout`
  determines whether the execution should continue or be canceled.

  When set to `CONTINUE`, the statement execution continues
  asynchronously and the call returns a statement ID which can be used
  for polling with
  [`db_sql_exec_status()`](https://databrickslabs.github.io/brickster/reference/db_sql_exec_status.md).

  When set to `CANCEL`, the statement execution is canceled and the call
  returns with a `CANCELED` state.

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

Refer to the [web
documentation](https://docs.databricks.com/api/workspace/statementexecution/executestatement)
for detailed material on interaction of the various parameters and
general recommendations

## See also

Other SQL Execution APIs:
[`db_sql_exec_cancel()`](https://databrickslabs.github.io/brickster/reference/db_sql_exec_cancel.md),
[`db_sql_exec_result()`](https://databrickslabs.github.io/brickster/reference/db_sql_exec_result.md),
[`db_sql_exec_status()`](https://databrickslabs.github.io/brickster/reference/db_sql_exec_status.md)
