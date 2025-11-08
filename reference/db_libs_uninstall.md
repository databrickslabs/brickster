# Uninstall Library on Cluster

Uninstall Library on Cluster

## Usage

``` r
db_libs_uninstall(
  cluster_id,
  libraries,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

- cluster_id:

  Unique identifier of a Databricks cluster.

- libraries:

  An object created by
  [`libraries()`](https://databrickslabs.github.io/brickster/reference/libraries.md)
  and the appropriate `lib_*()` functions.

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

The libraries aren’t uninstalled until the cluster is restarted.

Uninstalling libraries that are not installed on the cluster has no
impact but is not an error.

## See also

Other Libraries API:
[`db_libs_all_cluster_statuses()`](https://databrickslabs.github.io/brickster/reference/db_libs_all_cluster_statuses.md),
[`db_libs_cluster_status()`](https://databrickslabs.github.io/brickster/reference/db_libs_cluster_status.md),
[`db_libs_install()`](https://databrickslabs.github.io/brickster/reference/db_libs_install.md)
