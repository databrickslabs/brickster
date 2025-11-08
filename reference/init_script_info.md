# Init Script Info

Init Script Info

## Usage

``` r
init_script_info(...)
```

## Arguments

- ...:

  Accepts multiple instances
  [`s3_storage_info()`](https://databrickslabs.github.io/brickster/reference/s3_storage_info.md),
  [`file_storage_info()`](https://databrickslabs.github.io/brickster/reference/file_storage_info.md),
  or
  [`dbfs_storage_info()`](https://databrickslabs.github.io/brickster/reference/dbfs_storage_info.md).

## Details

[`file_storage_info()`](https://databrickslabs.github.io/brickster/reference/file_storage_info.md)
is only available for clusters set up using Databricks Container
Services.

For instructions on using init scripts with Databricks Container
Services, see [Use an init
script](https://docs.databricks.com/clusters/custom-containers.html#containers-init-script).

## See also

[`db_cluster_create()`](https://databrickslabs.github.io/brickster/reference/db_cluster_create.md),
[`db_cluster_edit()`](https://databrickslabs.github.io/brickster/reference/db_cluster_edit.md)
