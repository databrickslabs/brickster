# DBFS mkdirs

Create the given directory and necessary parent directories if they do
not exist.

## Usage

``` r
db_dbfs_mkdirs(
  path,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

- path:

  The path of the new file. The path should be the absolute DBFS path
  (for example `/mnt/my-file.txt`).

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

- If there exists a file (not a directory) at any prefix of the input
  path, this call throws an exception with `RESOURCE_ALREADY_EXISTS.`

- If this operation fails it may have succeeded in creating some of the
  necessary parent directories.

## See also

Other DBFS API:
[`db_dbfs_add_block()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_add_block.md),
[`db_dbfs_close()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_close.md),
[`db_dbfs_create()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_create.md),
[`db_dbfs_delete()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_delete.md),
[`db_dbfs_get_status()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_get_status.md),
[`db_dbfs_list()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_list.md),
[`db_dbfs_move()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_move.md),
[`db_dbfs_put()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_put.md),
[`db_dbfs_read()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_read.md)
