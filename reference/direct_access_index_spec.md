# Delta Sync Vector Search Index Specification

Delta Sync Vector Search Index Specification

## Usage

``` r
direct_access_index_spec(
  embedding_source_columns = NULL,
  embedding_vector_columns = NULL,
  schema
)
```

## Arguments

- embedding_source_columns:

  The columns that contain the embedding source, must be one or list of
  [`embedding_source_column()`](https://databrickslabs.github.io/brickster/reference/embedding_source_column.md)

- embedding_vector_columns:

  The columns that contain the embedding, must be one or list of
  [`embedding_vector_column()`](https://databrickslabs.github.io/brickster/reference/embedding_vector_column.md)
  vectors.

- schema:

  Named list, names are column names, values are types. See details.

## Details

The supported types are:

- `"integer"`

- `"long"`

- `"float"`

- `"double"`

- `"boolean"`

- `"string"`

- `"date"`

- `"timestamp"`

- `"array<float>"`: supported for vector columns

- `"array<double>"`: supported for vector columns

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
[`delta_sync_index_spec()`](https://databrickslabs.github.io/brickster/reference/delta_sync_index_spec.md),
[`embedding_source_column()`](https://databrickslabs.github.io/brickster/reference/embedding_source_column.md),
[`embedding_vector_column()`](https://databrickslabs.github.io/brickster/reference/embedding_vector_column.md)
