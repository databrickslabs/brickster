# DBFS Add Block

Append a block of data to the stream specified by the input handle.

## Usage

``` r
db_dbfs_add_block(
  handle,
  data,
  convert_to_raw = FALSE,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

- handle:

  Handle on an open stream.

- data:

  Either a path for file on local system or a character/raw vector that
  will be base64-encoded. This has a limit of 1 MB.

- convert_to_raw:

  Boolean (Default: `FALSE`), if `TRUE` will convert character vector to
  raw via [`base::as.raw()`](https://rdrr.io/r/base/raw.html).

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

- If the handle does not exist, this call will throw an exception with
  `RESOURCE_DOES_NOT_EXIST.`

- If the block of data exceeds 1 MB, this call will throw an exception
  with `MAX_BLOCK_SIZE_EXCEEDED.`

## Typical File Upload Flow

- Call create and get a handle via
  [`db_dbfs_create()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_create.md)

- Make one or more `db_dbfs_add_block()` calls with the handle you have

- Call
  [`db_dbfs_close()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_close.md)
  with the handle you have

## See also

Other DBFS API:
[`db_dbfs_close()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_close.md),
[`db_dbfs_create()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_create.md),
[`db_dbfs_delete()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_delete.md),
[`db_dbfs_get_status()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_get_status.md),
[`db_dbfs_list()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_list.md),
[`db_dbfs_mkdirs()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_mkdirs.md),
[`db_dbfs_move()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_move.md),
[`db_dbfs_put()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_put.md),
[`db_dbfs_read()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_read.md)
