# Get Schema (Unity Catalog)

Get Schema (Unity Catalog)

## Usage

``` r
db_uc_schemas_get(
  catalog,
  schema,
  include_browse = TRUE,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

- catalog:

  Parent catalog for schema of interest.

- schema:

  Schema of interest.

- include_browse:

  Whether to include catalogs in the response for which the principal
  can only access selective metadata for.

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

Other Unity Catalog Management:
[`db_uc_catalogs_get()`](https://databrickslabs.github.io/brickster/reference/db_uc_catalogs_get.md),
[`db_uc_catalogs_list()`](https://databrickslabs.github.io/brickster/reference/db_uc_catalogs_list.md),
[`db_uc_schemas_list()`](https://databrickslabs.github.io/brickster/reference/db_uc_schemas_list.md)
