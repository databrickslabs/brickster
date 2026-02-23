# Download Directory from Volume in Parallel

Download files from a volume directory to a local directory using
parallel requests.

## Usage

``` r
db_volume_download_dir(
  volume_dir,
  local_dir,
  overwrite = TRUE,
  recursive = TRUE,
  host = db_host(),
  token = db_token()
)
```

## Arguments

- volume_dir:

  Volume directory path (must start with /Volumes/)

- local_dir:

  Path to local directory where files will be downloaded

- overwrite:

  Flag to overwrite existing local files (default: `TRUE`)

- recursive:

  If `TRUE`, recursively include subdirectories (default: `TRUE`). If
  `FALSE`, only top-level files are transferred.

- host:

  Databricks workspace URL, defaults to calling
  [`db_host()`](https://databrickslabs.github.io/brickster/reference/db_host.md).

- token:

  Databricks workspace token, defaults to calling
  [`db_token()`](https://databrickslabs.github.io/brickster/reference/db_token.md).

## Value

TRUE if all downloads successful

## See also

Other Volumes FileSystem API:
[`db_volume_delete()`](https://databrickslabs.github.io/brickster/reference/db_volume_delete.md),
[`db_volume_dir_create()`](https://databrickslabs.github.io/brickster/reference/db_volume_dir_create.md),
[`db_volume_dir_delete()`](https://databrickslabs.github.io/brickster/reference/db_volume_dir_delete.md),
[`db_volume_dir_exists()`](https://databrickslabs.github.io/brickster/reference/db_volume_dir_exists.md),
[`db_volume_file_exists()`](https://databrickslabs.github.io/brickster/reference/db_volume_file_exists.md),
[`db_volume_list()`](https://databrickslabs.github.io/brickster/reference/db_volume_list.md),
[`db_volume_read()`](https://databrickslabs.github.io/brickster/reference/db_volume_read.md),
[`db_volume_upload_dir()`](https://databrickslabs.github.io/brickster/reference/db_volume_upload_dir.md),
[`db_volume_write()`](https://databrickslabs.github.io/brickster/reference/db_volume_write.md)
