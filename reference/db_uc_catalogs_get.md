# Get Catalog (Unity Catalog)

Get Catalog (Unity Catalog)

## Usage

``` r
db_uc_catalogs_get(
  catalog,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

- catalog:

  The name of the catalog.

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
[`db_uc_catalogs_list()`](https://databrickslabs.github.io/brickster/reference/db_uc_catalogs_list.md),
[`db_uc_schemas_get()`](https://databrickslabs.github.io/brickster/reference/db_uc_schemas_get.md),
[`db_uc_schemas_list()`](https://databrickslabs.github.io/brickster/reference/db_uc_schemas_list.md)
