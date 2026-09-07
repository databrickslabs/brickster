# Volume FileSystem List Directory Contents

Volume FileSystem List Directory Contents

## Usage

``` r
db_volume_list(
  path,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE,
  page_size = NULL,
  page_token = NULL
)
```

## Arguments

- path:

  Absolute path of the file in the Files API, omitting the initial
  slash.

- host:

  Databricks workspace URL, defaults to calling
  [`db_host()`](https://databrickslabs.github.io/brickster/reference/db_host.md).

- token:

  Databricks workspace token, defaults to calling
  [`db_token()`](https://databrickslabs.github.io/brickster/reference/db_token.md).

- perform_request:

  If `TRUE` (default) the request is performed, if `FALSE` the httr2
  request is returned *without* being performed.

- page_size:

  Maximum number of directory entries per page, from 0 to 1000. `NULL`
  uses the API default; 0 requests the maximum page size.

- page_token:

  Continuation token from a previous response, or `NULL` for the first
  page.

## Value

If `perform_request = TRUE`, returns one API response page, including
`contents` and `next_page_token` when present. If `FALSE`, returns an
`httr2_request`. Directory download and recursive-delete helpers fetch
all pages.

## See also

Other Volumes FileSystem API:
[`db_volume_delete()`](https://databrickslabs.github.io/brickster/reference/db_volume_delete.md),
[`db_volume_dir_create()`](https://databrickslabs.github.io/brickster/reference/db_volume_dir_create.md),
[`db_volume_dir_delete()`](https://databrickslabs.github.io/brickster/reference/db_volume_dir_delete.md),
[`db_volume_dir_exists()`](https://databrickslabs.github.io/brickster/reference/db_volume_dir_exists.md),
[`db_volume_download_dir()`](https://databrickslabs.github.io/brickster/reference/db_volume_download_dir.md),
[`db_volume_file_exists()`](https://databrickslabs.github.io/brickster/reference/db_volume_file_exists.md),
[`db_volume_read()`](https://databrickslabs.github.io/brickster/reference/db_volume_read.md),
[`db_volume_upload_dir()`](https://databrickslabs.github.io/brickster/reference/db_volume_upload_dir.md),
[`db_volume_write()`](https://databrickslabs.github.io/brickster/reference/db_volume_write.md)
