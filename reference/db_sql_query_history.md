# List Warehouse Query History

For more details refer to the [query history
documentation](https://docs.databricks.com/api/workspace/queryhistory/list).
This function elevates the sub-components of `filter_by` parameter to
the R function directly.

## Usage

``` r
db_sql_query_history(
  statuses = NULL,
  user_ids = NULL,
  endpoint_ids = NULL,
  start_time_ms = NULL,
  end_time_ms = NULL,
  max_results = 100,
  page_token = NULL,
  include_metrics = FALSE,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

- statuses:

  Allows filtering by query status. Possible values are: `QUEUED`,
  `RUNNING`, `CANCELED`, `FAILED`, `FINISHED`. Multiple permitted.

- user_ids:

  Allows filtering by user ID's. Multiple permitted.

- endpoint_ids:

  Allows filtering by endpoint ID's. Multiple permitted.

- start_time_ms:

  Integer, limit results to queries that started after this time.

- end_time_ms:

  Integer, limit results to queries that started before this time.

- max_results:

  Limit the number of results returned in one page. Default is 100.

- page_token:

  Opaque token used to get the next page of results. Optional.

- include_metrics:

  Whether to include metrics about query execution.

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

By default the filter parameters `statuses`, `user_ids`, and
`endpoints_ids` are `NULL`.
