# List Clusters

List Clusters

## Usage

``` r
db_cluster_list(
  host = db_host(),
  token = db_token(),
  perform_request = TRUE,
  page_size = 20,
  page_token = NULL
)
```

## Arguments

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

  Maximum number of clusters per page, from 1 to 100 (default: 20). Use
  `NULL` for the server default.

- page_token:

  A `next_page_token` or `prev_page_token` from a previous response, or
  `NULL` for the first page.

## Value

If `perform_request = TRUE`, returns the full single-page API response
with class `db_cluster_list`, including pagination tokens when present.
Each record in `clusters` has class `db_cluster`. If `FALSE`, returns an
`httr2_request`.

## Details

Retrieve one page of pinned and active clusters, and clusters terminated
within the past 30 days. Use `next_page_token` to request subsequent
pages. Extract `$clusters` to access the records; earlier versions
returned these records directly without pagination metadata.

## See also

[`db_list_all_pages()`](https://databrickslabs.github.io/brickster/reference/db_list_all_pages.md)
to collect records from every page.

Other Clusters API:
[`db_cluster_create()`](https://databrickslabs.github.io/brickster/reference/db_cluster_create.md),
[`db_cluster_edit()`](https://databrickslabs.github.io/brickster/reference/db_cluster_edit.md),
[`db_cluster_events()`](https://databrickslabs.github.io/brickster/reference/db_cluster_events.md),
[`db_cluster_get()`](https://databrickslabs.github.io/brickster/reference/db_cluster_get.md),
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

## Examples

``` r
if (FALSE) { # \dontrun{
page <- db_cluster_list()
clusters <- page$clusters
if (!is.null(page$next_page_token) && nzchar(page$next_page_token)) {
  next_page <- db_cluster_list(page_token = page$next_page_token)
}
} # }
```
