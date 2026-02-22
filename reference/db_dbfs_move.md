# DBFS Move

**\[deprecated\]**

## Usage

``` r
db_dbfs_move(
  source_path,
  destination_path,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

- source_path:

  The source path of the file or directory. The path should be the
  absolute DBFS path (for example, `/mnt/my-source-folder/`).

- destination_path:

  The destination path of the file or directory. The path should be the
  absolute DBFS path (for example, `/mnt/my-destination-folder/`).

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

Move a file from one location to another location within DBFS.

If the given source path is a directory, this call always recursively
moves all files.

When moving a large number of files, the API call will time out after
approximately 60 seconds, potentially resulting in partially moved data.
Therefore, for operations that move more than 10K files, we **strongly**
discourage using the DBFS REST API. Instead, we recommend that you
perform such operations in the context of a cluster, using the File
system utility (`dbutils.fs`) from a notebook, which provides the same
functionality without timing out.

- If the source file does not exist, this call throws an exception with
  `RESOURCE_DOES_NOT_EXIST.`

- If there already exists a file in the destination path, this call
  throws an exception with `RESOURCE_ALREADY_EXISTS.`

## See also

Other DBFS API:
[`db_dbfs_add_block()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_add_block.md),
[`db_dbfs_close()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_close.md),
[`db_dbfs_create()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_create.md),
[`db_dbfs_delete()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_delete.md),
[`db_dbfs_get_status()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_get_status.md),
[`db_dbfs_list()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_list.md),
[`db_dbfs_mkdirs()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_mkdirs.md),
[`db_dbfs_put()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_put.md),
[`db_dbfs_read()`](https://databrickslabs.github.io/brickster/reference/db_dbfs_read.md)
