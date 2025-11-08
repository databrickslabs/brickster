# List Catalogs (Unity Catalog)

List Catalogs (Unity Catalog)

## Usage

``` r
db_uc_catalogs_list(
  max_results = 1000,
  include_browse = TRUE,
  page_token = NULL,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

- max_results:

  Maximum number of catalogs to return (default: 1000).

- include_browse:

  Whether to include catalogs in the response for which the principal
  can only access selective metadata for.

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

Other Unity Catalog Management:
[`db_uc_catalogs_get()`](https://databrickslabs.github.io/brickster/reference/db_uc_catalogs_get.md),
[`db_uc_schemas_get()`](https://databrickslabs.github.io/brickster/reference/db_uc_schemas_get.md),
[`db_uc_schemas_list()`](https://databrickslabs.github.io/brickster/reference/db_uc_schemas_list.md)
