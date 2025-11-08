# Volume FileSystem Read

Return the contents of a file within a volume (up to 5GiB).

## Usage

``` r
db_volume_read(
  path,
  destination,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE,
  progress = TRUE
)
```

## Arguments

- path:

  Absolute path of the file in the Files API, omitting the initial
  slash.

- destination:

  Path to write downloaded file to.

- host:

  Databricks workspace URL, defaults to calling
  [`db_host()`](https://databrickslabs.github.io/brickster/reference/db_host.md).

- token:

  Databricks workspace token, defaults to calling
  [`db_token()`](https://databrickslabs.github.io/brickster/reference/db_token.md).

- perform_request:

  If `TRUE` (default) the request is performed, if `FALSE` the httr2
  request is returned *without* being performed.

- progress:

  If TRUE, show progress bar for file operations (default: TRUE for
  uploads/downloads, FALSE for other operations)

## See also

Other Volumes FileSystem API:
[`db_volume_delete()`](https://databrickslabs.github.io/brickster/reference/db_volume_delete.md),
[`db_volume_dir_create()`](https://databrickslabs.github.io/brickster/reference/db_volume_dir_create.md),
[`db_volume_dir_delete()`](https://databrickslabs.github.io/brickster/reference/db_volume_dir_delete.md),
[`db_volume_dir_exists()`](https://databrickslabs.github.io/brickster/reference/db_volume_dir_exists.md),
[`db_volume_file_exists()`](https://databrickslabs.github.io/brickster/reference/db_volume_file_exists.md),
[`db_volume_list()`](https://databrickslabs.github.io/brickster/reference/db_volume_list.md),
[`db_volume_upload_dir()`](https://databrickslabs.github.io/brickster/reference/db_volume_upload_dir.md),
[`db_volume_write()`](https://databrickslabs.github.io/brickster/reference/db_volume_write.md)
