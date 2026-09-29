# List Cluster Activity Events

List Cluster Activity Events

## Usage

``` r
db_cluster_events(
  cluster_id,
  start_time = NULL,
  end_time = NULL,
  event_types = NULL,
  order = c("DESC", "ASC"),
  offset = NULL,
  limit = NULL,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE,
  page_size = 50,
  page_token = NULL
)
```

## Arguments

- cluster_id:

  The ID of the cluster to retrieve events about.

- start_time:

  The start time in epoch milliseconds. If empty, returns events
  starting from the beginning of time.

- end_time:

  The end time in epoch milliseconds. If empty, returns events up to the
  current time.

- event_types:

  List. Optional set of event types to filter by. Default is to return
  all events. [Event
  Types](https://docs.databricks.com/api/workspace/clusters/events#events).

- order:

  Either `DESC` (default) or `ASC`.

- offset:

  **\[deprecated\]** Use `page_token` instead. Legacy result offset.
  When supplied, uses legacy pagination with a warning. Descending
  requests with an offset require `end_time`.

- limit:

  **\[deprecated\]** Use `page_size` instead. Legacy page size, from 1
  to 500. When supplied, uses legacy pagination with a warning.

- host:

  Databricks workspace URL, defaults to calling
  [`db_host()`](https://databrickslabs.github.io/brickster/reference/db_host.md).

- token:

  Databricks workspace token, defaults to calling
  [`db_token()`](https://databrickslabs.github.io/brickster/reference/db_token.md).

- perform_request:

  If `TRUE` (default) the request is performed, if `FALSE` the httr2
  request is returned *without* being performed.

- page_size:

  Maximum number of events per page, from 0 to 500 (default: 50). Use
  `0` or `NULL` for the server default.

- page_token:

  A `next_page_token` or `prev_page_token` from a previous response, or
  `NULL` for the first page.

## Value

If `perform_request = TRUE`, returns the full single-page API response,
including `events` and pagination metadata when present. If `FALSE`,
returns an `httr2_request`.

## Details

Retrieve one page of events about the activity of a cluster. Extract
`$events` to access the records; earlier versions returned the records
directly. Use the response's `next_page_token` or `prev_page_token` as
`page_token` to navigate pages, retaining the same time and event
filters.

`offset` and `limit` default to `NULL` and are omitted from token-based
requests. Non-`NULL` legacy arguments cannot be combined with an
explicitly supplied non-`NULL` `page_size` or `page_token`. Legacy
arguments are forwarded for compatibility, but Databricks deprecates
them on November 30, 2026. Migrate to `page_size` and tokens returned by
the preceding response; numeric offsets cannot be converted to page
tokens.

Supply epoch milliseconds as numeric values, not R integers.

## See also

[`db_list_all_pages()`](https://databrickslabs.github.io/brickster/reference/db_list_all_pages.md)
to collect records from every page.

Other Clusters API:
[`db_cluster_create()`](https://databrickslabs.github.io/brickster/reference/db_cluster_create.md),
[`db_cluster_edit()`](https://databrickslabs.github.io/brickster/reference/db_cluster_edit.md),
[`db_cluster_get()`](https://databrickslabs.github.io/brickster/reference/db_cluster_get.md),
[`db_cluster_list()`](https://databrickslabs.github.io/brickster/reference/db_cluster_list.md),
[`db_cluster_list_node_types()`](https://databrickslabs.github.io/brickster/reference/db_cluster_list_node_types.md),
[`db_cluster_list_zones()`](https://databrickslabs.github.io/brickster/reference/db_cluster_list_zones.md),
[`db_cluster_perm_delete()`](https://databrickslabs.github.io/brickster/reference/db_cluster_perm_delete.md),
[`db_cluster_pin()`](https://databrickslabs.github.io/brickster/reference/db_cluster_pin.md),
[`db_cluster_resize()`](https://databrickslabs.github.io/brickster/reference/db_cluster_resize.md),
[`db_cluster_restart()`](https://databrickslabs.github.io/brickster/reference/db_cluster_restart.md),
[`db_cluster_runtime_versions()`](https://databrickslabs.github.io/brickster/reference/db_cluster_runtime_versions.md),
[`db_cluster_start()`](https://databrickslabs.github.io/brickster/reference/db_cluster_start.md),
[`db_cluster_terminate()`](https://databrickslabs.github.io/brickster/reference/db_cluster_terminate.md),
[`db_cluster_unpin()`](https://databrickslabs.github.io/brickster/reference/db_cluster_unpin.md),
[`get_and_start_cluster()`](https://databrickslabs.github.io/brickster/reference/get_and_start_cluster.md),
[`get_latest_dbr()`](https://databrickslabs.github.io/brickster/reference/get_latest_dbr.md)
