# Update Volume (Unity Catalog)

Update Volume (Unity Catalog)

## Usage

``` r
db_uc_volumes_create(
  catalog,
  schema,
  volume,
  volume_type = c("MANAGED", "EXTERNAL"),
  storage_location = NULL,
  comment = NULL,
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

- volume:

  Volume name.

- volume_type:

  Either `'MANAGED'` or `'EXTERNAL'`.

- storage_location:

  The storage location on the cloud, only specified when `volume_type`
  is `'EXTERNAL'`.

- comment:

  The comment attached to the volume.

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
[`db_uc_volumes_delete()`](https://databrickslabs.github.io/brickster/reference/db_uc_volumes_delete.md),
[`db_uc_volumes_get()`](https://databrickslabs.github.io/brickster/reference/db_uc_volumes_get.md),
[`db_uc_volumes_list()`](https://databrickslabs.github.io/brickster/reference/db_uc_volumes_list.md),
[`db_uc_volumes_update()`](https://databrickslabs.github.io/brickster/reference/db_uc_volumes_update.md)
