# DBFS Put

Upload a file through the use of multipart form post.

## Usage

``` r
db_dbfs_put(
  path,
  file = NULL,
  contents = NULL,
  overwrite = FALSE,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

- path:

  The path of the new file. The path should be the absolute DBFS path
  (for example `/mnt/my-file.txt`).

- file:

  Path to a file on local system, takes precedent over `path`.

- contents:

  String that is base64 encoded.

- overwrite:

  Flag (Default: `FALSE`) that specifies whether to overwrite existing
  files.

- host:

  Databricks workspace URL, defaults to calling
  [`db_host()`](https://databrickslabs.github.io/brickster/reference/db_host.md).

- token:

  Databricks workspace token, defaults to calling
  [`db_token()`](https://databrickslabs.github.io/brickster/reference/db_token.md).

- perform_request:

  If `TRUE` (default) the request is performed, if `FALSE` the httr2
  request is returned *without* being performed.

## Details

Either `contents` or `file` must be specified. `file` takes precedent
over `contents` if both are specified.

Mainly used for streaming uploads, but can also be used as a convenient
single call for data upload.

The amount of data that can be passed using the contents parameter is
limited to 1 MB if specified as a string (`MAX_BLOCK_SIZE_EXCEEDED` is
thrown if exceeded) and 2 GB as a file.

## See also

Other DBFS API:
[`db_dbfs_add_block()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_add_block.md),
[`db_dbfs_close()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_close.md),
[`db_dbfs_create()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_create.md),
[`db_dbfs_delete()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_delete.md),
[`db_dbfs_get_status()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_get_status.md),
[`db_dbfs_list()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_list.md),
[`db_dbfs_mkdirs()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_mkdirs.md),
[`db_dbfs_move()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_move.md),
[`db_dbfs_read()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_read.md)
