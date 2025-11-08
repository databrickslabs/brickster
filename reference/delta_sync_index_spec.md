# Delta Sync Vector Search Index Specification

Delta Sync Vector Search Index Specification

## Usage

``` r
delta_sync_index_spec(
  source_table,
  embedding_writeback_table = NULL,
  embedding_source_columns = NULL,
  embedding_vector_columns = NULL,
  pipeline_type = c("TRIGGERED", "CONTINUOUS")
)
```

## Arguments

- source_table:

  The name of the source table.

- embedding_writeback_table:

  Name of table to sync index contents and computed embeddings back to
  delta table, see details.

- embedding_source_columns:

  The columns that contain the embedding source, must be one or list of
  [`embedding_source_column()`](https://databrickslabs.github.io/brickster/reference/embedding_source_column.md)

- embedding_vector_columns:

  The columns that contain the embedding, must be one or list of
  [`embedding_vector_column()`](https://databrickslabs.github.io/brickster/reference/embedding_vector_column.md)

- pipeline_type:

  Pipeline execution mode, see details.

## Details

`pipeline_type` is either:

- `"TRIGGERED"`: If the pipeline uses the triggered execution mode, the
  system stops processing after successfully refreshing the source table
  in the pipeline once, ensuring the table is updated based on the data
  available when the update started.

- `"CONTINUOUS"` If the pipeline uses continuous execution, the pipeline
  processes new data as it arrives in the source table to keep vector
  index fresh.

The only supported naming convention for `embedding_writeback_table` is
`"<index_name>_writeback_table"`.

## See also

[`db_vs_indexes_create()`](https://databrickslabs.github.io/brickster/reference/db_vs_indexes_create.md)

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
[`db_vs_indexes_query()`](https://databrickslabs.github.io/brickster/reference/db_vs_indexes_query.md),
[`db_vs_indexes_query_next_page()`](https://databrickslabs.github.io/brickster/reference/db_vs_indexes_query_next_page.md),
[`db_vs_indexes_scan()`](https://databrickslabs.github.io/brickster/reference/db_vs_indexes_scan.md),
[`db_vs_indexes_sync()`](https://databrickslabs.github.io/brickster/reference/db_vs_indexes_sync.md),
[`db_vs_indexes_upsert_data()`](https://databrickslabs.github.io/brickster/reference/db_vs_indexes_upsert_data.md),
[`direct_access_index_spec()`](https://databrickslabs.github.io/brickster/reference/direct_access_index_spec.md),
[`embedding_source_column()`](https://databrickslabs.github.io/brickster/reference/embedding_source_column.md),
[`embedding_vector_column()`](https://databrickslabs.github.io/brickster/reference/embedding_vector_column.md)
