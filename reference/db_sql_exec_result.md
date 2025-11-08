# Get SQL Query Results

Get SQL Query Results

## Usage

``` r
db_sql_exec_result(
  statement_id,
  chunk_index,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

- statement_id:

  String, query execution `statement_id`

- chunk_index:

  Integer, chunk index to fetch result. Starts from `0`.

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

After the statement execution has `SUCCEEDED`, this request can be used
to fetch any chunk by index.

Whereas the first chunk with chunk_index = `0` is typically fetched with
`db_sql_exec_result()` or
[`db_sql_exec_status()`](https://databrickslabs.github.io/brickster/reference/db_sql_exec_status.md),
this request can be used to fetch subsequent chunks

The response structure is identical to the nested result element
described in the `db_sql_exec_result()` request, and similarly includes
the `next_chunk_index` and `next_chunk_internal_link` fields for simple
iteration through the result set.

[Read more on Databricks API
docs](https://docs.databricks.com/api/workspace/statementexecution/getstatementresultchunkn)

## See also

Other SQL Execution APIs:
[`db_sql_exec_cancel()`](https://databrickslabs.github.io/brickster/reference/db_sql_exec_cancel.md),
[`db_sql_exec_query()`](https://databrickslabs.github.io/brickster/reference/db_sql_exec_query.md),
[`db_sql_exec_status()`](https://databrickslabs.github.io/brickster/reference/db_sql_exec_status.md)
