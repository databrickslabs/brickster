# Cluster Log Configuration

Path to cluster log.

## Usage

``` r
cluster_log_conf(dbfs = NULL, s3 = NULL)
```

## Arguments

- dbfs:

  Instance of
  [`dbfs_storage_info()`](https://databrickslabs.github.io/brickster/reference/dbfs_storage_info.md).

- s3:

  Instance of
  [`s3_storage_info()`](https://databrickslabs.github.io/brickster/reference/s3_storage_info.md).

## Details

`dbfs` and `s3` are mutually exclusive, logs can only be sent to one
destination.

## See also

Other Cluster Log Configuration Objects:
[`dbfs_storage_info()`](https://databrickslabs.github.io/brickster/reference/dbfs_storage_info.md),
[`s3_storage_info()`](https://databrickslabs.github.io/brickster/reference/s3_storage_info.md)
