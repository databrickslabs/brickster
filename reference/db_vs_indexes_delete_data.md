# Delete Data from a Vector Search Index

Delete Data from a Vector Search Index

## Usage

``` r
db_vs_indexes_delete_data(
  index,
  primary_keys,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

- index:

  Name of vector search index

- primary_keys:

  primary keys to be deleted from index

- host:

  Databricks workspace URL, defaults to calling
  [`db_host()`](https://databrickslabs.github.io/brickster/reference/db_host.md).

- token:

  Databricks workspace token, defaults to calling
  [`db_token()`](https://databrickslabs.github.io/brickster/reference/db_token.md).

- perform_request:

  If `TRUE` (default) the request is performed, if `FALSE` the httr2
  request is returned *without* being performed.

## See also

Other Vector Search API:
[`db_vs_endpoints_create()`](https://databrickslabs.github.io/brickster/reference/db_vs_endpoints_create.md),
[`db_vs_endpoints_delete()`](https://databrickslabs.github.io/brickster/reference/db_vs_endpoints_delete.md),
[`db_vs_endpoints_get()`](https://databrickslabs.github.io/brickster/reference/db_vs_endpoints_get.md),
[`db_vs_endpoints_list()`](https://databrickslabs.github.io/brickster/reference/db_vs_endpoints_list.md),
[`db_vs_indexes_create()`](https://databrickslabs.github.io/brickster/reference/db_vs_indexes_create.md),
[`db_vs_indexes_delete()`](https://databrickslabs.github.io/brickster/reference/db_vs_indexes_delete.md),
[`db_vs_indexes_get()`](https://databrickslabs.github.io/brickster/reference/db_vs_indexes_get.md),
[`db_vs_indexes_list()`](https://databrickslabs.github.io/brickster/reference/db_vs_indexes_list.md),
[`db_vs_indexes_query()`](https://databrickslabs.github.io/brickster/reference/db_vs_indexes_query.md),
[`db_vs_indexes_query_next_page()`](https://databrickslabs.github.io/brickster/reference/db_vs_indexes_query_next_page.md),
[`db_vs_indexes_scan()`](https://databrickslabs.github.io/brickster/reference/db_vs_indexes_scan.md),
[`db_vs_indexes_sync()`](https://databrickslabs.github.io/brickster/reference/db_vs_indexes_sync.md),
[`db_vs_indexes_upsert_data()`](https://databrickslabs.github.io/brickster/reference/db_vs_indexes_upsert_data.md),
[`delta_sync_index_spec()`](https://databrickslabs.github.io/brickster/reference/delta_sync_index_spec.md),
[`direct_access_index_spec()`](https://databrickslabs.github.io/brickster/reference/direct_access_index_spec.md),
[`embedding_source_column()`](https://databrickslabs.github.io/brickster/reference/embedding_source_column.md),
[`embedding_vector_column()`](https://databrickslabs.github.io/brickster/reference/embedding_vector_column.md)
