# Check Table Exists (Unity Catalog)

Check Table Exists (Unity Catalog)

## Usage

``` r
db_uc_tables_exists(
  catalog,
  schema,
  table,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

- catalog:

  Parent catalog of table.

- schema:

  Parent schema of table.

- table:

  Table name.

- host:

  Databricks workspace URL, defaults to calling
  [`db_host()`](https://databrickslabs.github.io/brickster/reference/db_host.md).

- token:

  Databricks workspace token, defaults to calling
  [`db_token()`](https://databrickslabs.github.io/brickster/reference/db_token.md).

- perform_request:

  If `TRUE` (default) the request is performed, if `FALSE` the httr2
  request is returned *without* being performed.

## Value

List with fields `table_exists` and `supports_foreign_metadata_update`

## See also

Other Unity Catalog Table Management:
[`db_uc_tables_delete()`](https://databrickslabs.github.io/brickster/reference/db_uc_tables_delete.md),
[`db_uc_tables_get()`](https://databrickslabs.github.io/brickster/reference/db_uc_tables_get.md),
[`db_uc_tables_list()`](https://databrickslabs.github.io/brickster/reference/db_uc_tables_list.md),
[`db_uc_tables_summaries()`](https://databrickslabs.github.io/brickster/reference/db_uc_tables_summaries.md)
