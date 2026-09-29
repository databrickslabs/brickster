# Collect Records from All API Response Pages

Collect Records from All API Response Pages

## Usage

``` r
db_list_all_pages(list_page_fn, ...)
```

## Arguments

- list_page_fn:

  A listing function, such as
  [`db_cluster_list()`](https://databrickslabs.github.io/brickster/reference/db_cluster_list.md),
  [`db_cluster_events()`](https://databrickslabs.github.io/brickster/reference/db_cluster_events.md),
  or
  [`db_jobs_list()`](https://databrickslabs.github.io/brickster/reference/db_jobs_list.md).
  It must accept `page_token` and return a named list containing record
  collections and, when more pages are available, `next_page_token`.

- ...:

  Arguments passed to `list_page_fn` on every request, including
  filters, page size, `host`, and `token`. Leave `page_token` and
  `perform_request` at their defaults; this helper fetches the pages.

## Value

A list of records from all pages, in request order, with record classes
and nested fields preserved. Pagination metadata is omitted. Returns
[`list()`](https://rdrr.io/r/base/list.html) when there are no records.
All pages are held in memory.

## Details

Removes the top-level pagination fields `next_page_token`,
`prev_page_token`, `next_page`, `total_count`, `has_more`, and
`has_next_page`, then combines the remaining record collections. No
collection field name is needed. Use a listing function whose remaining
response fields contain lists of records. Wrappers that already flatten
their response, such as
[`db_lakebase_list()`](https://databrickslabs.github.io/brickster/reference/db_lakebase_list.md),
are not supported.

Uses token pagination, starting at the first page. Leave legacy
pagination arguments unset, such as `offset` and `limit` in
[`db_cluster_events()`](https://databrickslabs.github.io/brickster/reference/db_cluster_events.md).
Empty pages with a continuation token are followed. Request errors and
repeated tokens stop collection with an error.

## See also

Other Request Helpers:
[`db_perform_request()`](https://databrickslabs.github.io/brickster/reference/db_perform_request.md),
[`db_perform_response()`](https://databrickslabs.github.io/brickster/reference/db_perform_response.md),
[`db_req_error_body()`](https://databrickslabs.github.io/brickster/reference/db_req_error_body.md),
[`db_request()`](https://databrickslabs.github.io/brickster/reference/db_request.md),
[`db_request_json()`](https://databrickslabs.github.io/brickster/reference/db_request_json.md)

## Examples

``` r
if (FALSE) { # \dontrun{
clusters <- db_list_all_pages(db_cluster_list, page_size = 100)
events <- db_list_all_pages(db_cluster_events, cluster_id = "cluster-id")
jobs <- db_list_all_pages(db_jobs_list, limit = 100)
} # }
```
