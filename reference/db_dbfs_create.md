# DBFS Create

**\[deprecated\]**

## Usage

``` r
db_dbfs_create(
  path,
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

- overwrite:

  Boolean, specifies whether to overwrite existing file or files.

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

Handle which should subsequently be passed into
[`db_dbfs_add_block()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_add_block.md)
and
[`db_dbfs_close()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_close.md)
when writing to a file through a stream.

## Details

Open a stream to write to a file and returns a handle to this stream.

There is a 10 minute idle timeout on this handle. If a file or directory
already exists on the given path and overwrite is set to `FALSE`, this
call throws an exception with `RESOURCE_ALREADY_EXISTS.`

## Typical File Upload Flow

- Call create and get a handle via `db_dbfs_create()`

- Make one or more
  [`db_dbfs_add_block()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_add_block.md)
  calls with the handle you have

- Call
  [`db_dbfs_close()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_close.md)
  with the handle you have

## See also

Other DBFS API:
[`db_dbfs_add_block()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_add_block.md),
[`db_dbfs_close()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_close.md),
[`db_dbfs_delete()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_delete.md),
[`db_dbfs_get_status()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_get_status.md),
[`db_dbfs_list()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_list.md),
[`db_dbfs_mkdirs()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_mkdirs.md),
[`db_dbfs_move()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_move.md),
[`db_dbfs_put()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_put.md),
[`db_dbfs_read()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_read.md)
