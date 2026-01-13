# Execute query with SQL Warehouse

Execute query with SQL Warehouse

## Usage

``` r
db_sql_query(
  warehouse_id,
  statement,
  schema = NULL,
  catalog = NULL,
  parameters = NULL,
  row_limit = NULL,
  byte_limit = NULL,
  wait_timeout = "5s",
  return_arrow = FALSE,
  max_active_connections = 30,
  fetch_timeout = 300,
  disposition = "EXTERNAL_LINKS",
  host = db_host(),
  token = db_token(),
  show_progress = TRUE
)
```

## Arguments

- warehouse_id:

  String, ID of warehouse upon which to execute a statement.

- statement:

  String, the SQL statement to execute. The statement can optionally be
  parameterized, see `parameters`.

- schema:

  String, sets default schema for statement execution, similar to
  `USE SCHEMA` in SQL.

- catalog:

  String, sets default catalog for statement execution, similar to
  `USE CATALOG` in SQL.

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

- return_arrow:

  Boolean, determine if result is
  [tibble::tibble](https://tibble.tidyverse.org/reference/tibble.html)
  or arrow::Table.

- max_active_connections:

  Integer to decide on concurrent downloads.

- fetch_timeout:

  Integer, timeout in seconds for downloading each result chunk

- disposition:

  Disposition mode ("INLINE" or "EXTERNAL_LINKS")

- host:

  Databricks workspace URL, defaults to calling
  [`db_host()`](https://databrickslabs.github.io/brickster/reference/db_host.md).

- token:

  Databricks workspace token, defaults to calling
  [`db_token()`](https://databrickslabs.github.io/brickster/reference/db_token.md).

- show_progress:

  If `TRUE`, show progress updates during query execution (default:
  `TRUE`)

## Value

[tibble::tibble](https://tibble.tidyverse.org/reference/tibble.html) or
arrow::Table.
