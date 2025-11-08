# List Table Summaries (Unity Catalog)

List Table Summaries (Unity Catalog)

## Usage

``` r
db_uc_tables_summaries(
  catalog,
  schema_name_pattern = NULL,
  table_name_pattern = NULL,
  max_results = 10000,
  include_manifest_capabilities = FALSE,
  page_token = NULL,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

- catalog:

  Name of parent catalog for tables of interest.

- schema_name_pattern:

  A sql `LIKE` pattern (`%` and `_`) for schema names. All schemas will
  be returned if not set or empty.

- table_name_pattern:

  A sql `LIKE` pattern (`%` and `_`) for table names. All tables will be
  returned if not set or empty.

- max_results:

  Maximum number of summaries for tables to return (default: 10000, max:
  10000). If not set, the page length is set to a server configured
  value.

- include_manifest_capabilities:

  Whether to include a manifest containing capabilities the table has.

- page_token:

  Opaque token used to get the next page of results. Optional.

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

List

## See also

Other Unity Catalog Table Management:
[`db_uc_tables_delete()`](https://databrickslabs.github.io/brickster/reference/db_uc_tables_delete.md),
[`db_uc_tables_exists()`](https://databrickslabs.github.io/brickster/reference/db_uc_tables_exists.md),
[`db_uc_tables_get()`](https://databrickslabs.github.io/brickster/reference/db_uc_tables_get.md),
[`db_uc_tables_list()`](https://databrickslabs.github.io/brickster/reference/db_uc_tables_list.md)
