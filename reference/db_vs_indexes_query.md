# Query a Vector Search Index

Query a Vector Search Index

## Usage

``` r
db_vs_indexes_query(
  index,
  columns,
  filters_json,
  query_vector = NULL,
  query_text = NULL,
  score_threshold = 0,
  query_type = c("ANN", "HYBRID"),
  num_results = 10,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

- index:

  Name of vector search index

- columns:

  Column names to include in response

- filters_json:

  JSON string representing query filters, see details.

- query_vector:

  Numeric vector. Required for direct vector access index and delta sync
  index using self managed vectors.

- query_text:

  Required for delta sync index using model endpoint.

- score_threshold:

  Numeric score threshold for the approximate nearest neighbour (ANN)
  search. Defaults to 0.0.

- query_type:

  One of `ANN` (default) or `HYBRID`

- num_results:

  Number of returns to return (default: 10).

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

You cannot specify both `query_vector` and `query_text` at the same
time.

`filter_jsons` examples:

- `'{"id <": 5}'`: Filter for id less than 5

- `'{"id >": 5}'`: Filter for id greater than 5

- `'{"id <=": 5}'`: Filter for id less than equal to 5

- `'{"id >=": 5}'`: Filter for id greater than equal to 5

- `'{"id": 5}'`: Filter for id equal to 5

- `'{"id": 5, "age >=": 18}'`: Filter for id equal to 5 and age greater
  than equal to 18

`filter_jsons` will convert attempt to use
[`jsonlite::toJSON`](https://jeroen.r-universe.dev/jsonlite/reference/fromJSON.html)
on any non character vectors.

Refer to docs for [Vector
Search](https://docs.databricks.com/en/generative-ai/create-query-vector-search.html#use-filters-on-queries).

## See also

Other Vector Search API:
[`db_vs_endpoints_create()`](https://databrickslabs.github.io/brickster/reference/db_vs_endpoints_create.md),
[`db_vs_endpoints_delete()`](https://databrickslabs.github.io/brickster/reference/db_vs_endpoints_delete.md),
[`db_vs_endpoints_get()`](https://databrickslabs.github.io/brickster/reference/db_vs_endpoints_get.md),
[`db_vs_endpoints_list()`](https://databrickslabs.github.io/brickster/reference/db_vs_endpoints_list.md),
[`db_vs_indexes_create()`](https://databrickslabs.github.io/brickster/reference/db_vs_indexes_create.md),
[`db_vs_indexes_delete()`](https://databrickslabs.github.io/brickster/reference/db_vs_indexes_delete.md),
[`db_vs_indexes_delete_data()`](https://databrickslabs.github.io/brickster/reference/db_vs_indexes_delete_data.md),
[`db_vs_indexes_get()`](https://databrickslabs.github.io/brickster/reference/db_vs_indexes_get.md),
[`db_vs_indexes_list()`](https://databrickslabs.github.io/brickster/reference/db_vs_indexes_list.md),
[`db_vs_indexes_query_next_page()`](https://databrickslabs.github.io/brickster/reference/db_vs_indexes_query_next_page.md),
[`db_vs_indexes_scan()`](https://databrickslabs.github.io/brickster/reference/db_vs_indexes_scan.md),
[`db_vs_indexes_sync()`](https://databrickslabs.github.io/brickster/reference/db_vs_indexes_sync.md),
[`db_vs_indexes_upsert_data()`](https://databrickslabs.github.io/brickster/reference/db_vs_indexes_upsert_data.md),
[`delta_sync_index_spec()`](https://databrickslabs.github.io/brickster/reference/delta_sync_index_spec.md),
[`direct_access_index_spec()`](https://databrickslabs.github.io/brickster/reference/direct_access_index_spec.md),
[`embedding_source_column()`](https://databrickslabs.github.io/brickster/reference/embedding_source_column.md),
[`embedding_vector_column()`](https://databrickslabs.github.io/brickster/reference/embedding_vector_column.md)

## Examples

``` r
if (FALSE) { # \dontrun{
db_vs_indexes_sync(
  index = "myindex",
  columns = c("id", "text"),
  query_vector = c(1, 2, 3)
)
} # }
```
