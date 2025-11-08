# List Tables (Unity Catalog)

List Tables (Unity Catalog)

## Usage

``` r
db_uc_tables_list(
  catalog,
  schema,
  max_results = 50,
  omit_columns = TRUE,
  omit_properties = TRUE,
  omit_username = TRUE,
  include_browse = TRUE,
  include_delta_metadata = FALSE,
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

- schema:

  Parent schema of tables.

- max_results:

  Maximum number of tables to return (default: 50, max: 50).

- omit_columns:

  Whether to omit the columns of the table from the response or not.

- omit_properties:

  Whether to omit the properties of the table from the response or not.

- omit_username:

  Whether to omit the username of the table (e.g. owner, updated_by,
  created_by) from the response or not.

- include_browse:

  Whether to include tables in the response for which the principal can
  only access selective metadata for.

- include_delta_metadata:

  Whether delta metadata should be included in the response.

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
[`db_uc_tables_summaries()`](https://databrickslabs.github.io/brickster/reference/db_uc_tables_summaries.md)
