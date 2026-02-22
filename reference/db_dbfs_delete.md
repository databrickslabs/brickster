# DBFS Delete

**\[deprecated\]**

## Usage

``` r
db_dbfs_delete(
  path,
  recursive = FALSE,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

- path:

  The path of the new file. The path should be the absolute DBFS path
  (for example `/mnt/my-file.txt`).

- recursive:

  Whether or not to recursively delete the directory’s contents.
  Deleting empty directories can be done without providing the recursive
  flag.

- host:

  Databricks workspace URL, defaults to calling
  [`db_host()`](https://databrickslabs.github.io/brickster/reference/db_host.md).

- token:

  Databricks workspace token, defaults to calling
  [`db_token()`](https://databrickslabs.github.io/brickster/reference/db_token.md).

- perform_request:

  If `TRUE` (default) the request is performed, if `FALSE` the httr2
  request is returned *without* being performed.

## See also

Other DBFS API:
[`db_dbfs_add_block()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_add_block.md),
[`db_dbfs_close()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_close.md),
[`db_dbfs_create()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_create.md),
[`db_dbfs_get_status()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_get_status.md),
[`db_dbfs_list()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_list.md),
[`db_dbfs_mkdirs()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_mkdirs.md),
[`db_dbfs_move()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_move.md),
[`db_dbfs_put()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_put.md),
[`db_dbfs_read()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_read.md)
