# Get Status of Libraries on Cluster

Get Status of Libraries on Cluster

## Usage

``` r
db_libs_cluster_status(
  cluster_id,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

- cluster_id:

  Unique identifier of a Databricks cluster.

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

[`wait_for_lib_installs()`](https://databrickslabs.github.io/brickster/reference/wait_for_lib_installs.md)

Other Libraries API:
[`db_libs_all_cluster_statuses()`](https://databrickslabs.github.io/brickster/reference/db_libs_all_cluster_statuses.md),
[`db_libs_install()`](https://databrickslabs.github.io/brickster/reference/db_libs_install.md),
[`db_libs_uninstall()`](https://databrickslabs.github.io/brickster/reference/db_libs_uninstall.md)
