# Execute SQL Query and Wait for Completion

Internal helper that executes a query and waits for completion. This
separates the execution/polling logic from result fetching.

## Usage

``` r
db_sql_exec_and_wait(
  warehouse_id,
  statement,
  catalog = NULL,
  schema = NULL,
  parameters = NULL,
  row_limit = NULL,
  byte_limit = NULL,
  wait_timeout = "0s",
  disposition = c("EXTERNAL_LINKS", "INLINE"),
  format = c("ARROW_STREAM", "JSON_ARRAY"),
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

- wait_timeout:

  Initial wait timeout (default "30s")

- disposition:

  One of `"INLINE"` (default) or `"EXTERNAL_LINKS"`. See
  [docs](https://docs.databricks.com/api/workspace/statementexecution/executestatement)
  for details.

- format:

  One of `"JSON_ARRAY"` (default), `"ARROW_STREAM"`, or `"CSV"`. See
  [docs](https://docs.databricks.com/api/workspace/statementexecution/executestatement)
  for details.

- host:

  Databricks workspace URL, defaults to calling
  [`db_host()`](https://databrickslabs.github.io/brickster/reference/db_host.md).

- token:

  Databricks workspace token, defaults to calling
  [`db_token()`](https://databrickslabs.github.io/brickster/reference/db_token.md).

## Value

Status response with manifest when query completes successfully
