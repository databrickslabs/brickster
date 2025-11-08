# List Volumes (Unity Catalog)

List Volumes (Unity Catalog)

## Usage

``` r
db_uc_volumes_list(
  catalog,
  schema,
  max_results = 10000,
  include_browse = TRUE,
  page_token = NULL,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

- catalog:

  Parent catalog of volume

- schema:

  Parent schema of volume

- max_results:

  Maximum number of volumes to return (default: 10000).

- include_browse:

  Whether to include volumes in the response for which the principal can
  only access selective metadata for.

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

Other Unity Catalog Volume Management:
[`db_uc_volumes_create()`](https://databrickslabs.github.io/brickster/reference/db_uc_volumes_create.md),
[`db_uc_volumes_delete()`](https://databrickslabs.github.io/brickster/reference/db_uc_volumes_delete.md),
[`db_uc_volumes_get()`](https://databrickslabs.github.io/brickster/reference/db_uc_volumes_get.md),
[`db_uc_volumes_update()`](https://databrickslabs.github.io/brickster/reference/db_uc_volumes_update.md)
