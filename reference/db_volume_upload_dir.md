# Upload Directory to Volume in Parallel

Upload all files from a local directory to a volume directory using
parallel requests.

## Usage

``` r
db_volume_upload_dir(
  local_dir,
  volume_dir,
  overwrite = TRUE,
  preserve_structure = TRUE,
  host = db_host(),
  token = db_token()
)
```

## Arguments

- local_dir:

  Path to local directory containing files to upload

- volume_dir:

  Volume directory path (must start with /Volumes/)

- overwrite:

  Flag to overwrite existing files (default: TRUE)

- preserve_structure:

  If TRUE, preserve subdirectory structure (default: TRUE)

- host:

  Databricks workspace URL, defaults to calling
  [`db_host()`](https://databrickslabs.github.io/brickster/reference/db_host.md).

- token:

  Databricks workspace token, defaults to calling
  [`db_token()`](https://databrickslabs.github.io/brickster/reference/db_token.md).

## Value

TRUE if all uploads successful

## See also

Other Volumes FileSystem API:
[`db_volume_delete()`](https://databrickslabs.github.io/brickster/reference/db_volume_delete.md),
[`db_volume_dir_create()`](https://databrickslabs.github.io/brickster/reference/db_volume_dir_create.md),
[`db_volume_dir_delete()`](https://databrickslabs.github.io/brickster/reference/db_volume_dir_delete.md),
[`db_volume_dir_exists()`](https://databrickslabs.github.io/brickster/reference/db_volume_dir_exists.md),
[`db_volume_file_exists()`](https://databrickslabs.github.io/brickster/reference/db_volume_file_exists.md),
[`db_volume_list()`](https://databrickslabs.github.io/brickster/reference/db_volume_list.md),
[`db_volume_read()`](https://databrickslabs.github.io/brickster/reference/db_volume_read.md),
[`db_volume_write()`](https://databrickslabs.github.io/brickster/reference/db_volume_write.md)
