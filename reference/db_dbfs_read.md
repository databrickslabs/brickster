# DBFS Read

**\[deprecated\]**

## Usage

``` r
db_dbfs_read(
  path,
  offset = 0,
  length = NULL,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

- path:

  The path of the new file. The path should be the absolute DBFS path
  (for example `/mnt/my-file.txt`).

- offset:

  Offset to read from in bytes.

- length:

  Number of bytes to read starting from the offset. This has a limit of
  1 MB, and a default value of 0.5 MB.

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

Return the contents of a file.

If offset + length exceeds the number of bytes in a file, reads contents
until the end of file.

- If the file does not exist, this call throws an exception with
  `RESOURCE_DOES_NOT_EXIST.`

- If the path is a directory, the read length is negative, or if the
  offset is negative, this call throws an exception with
  `INVALID_PARAMETER_VALUE.`

- If the read length exceeds 1 MB, this call throws an exception with
  `MAX_READ_SIZE_EXCEEDED.`

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
[`db_dbfs_put()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_put.md)
