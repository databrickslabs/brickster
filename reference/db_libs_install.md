# Install Library on Cluster

Install Library on Cluster

## Usage

``` r
db_libs_install(
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

Installation is asynchronous - it completes in the background after the
request.

This call will fail if the cluster is terminated. Installing a wheel
library on a cluster is like running the pip command against the wheel
file directly on driver and executors.

Installing a wheel library on a cluster is like running the pip command
against the wheel file directly on driver and executors. All the
dependencies specified in the library setup.py file are installed and
this requires the library name to satisfy the wheel file name
convention.

The installation on the executors happens only when a new task is
launched. With Databricks Runtime 7.1 and below, the installation order
of libraries is nondeterministic. For wheel libraries, you can ensure a
deterministic installation order by creating a zip file with suffix
.wheelhouse.zip that includes all the wheel files.

## See also

[`lib_egg()`](https://databrickslabs.github.io/brickster/reference/lib_egg.md),
[`lib_cran()`](https://databrickslabs.github.io/brickster/reference/lib_cran.md),
[`lib_jar()`](https://databrickslabs.github.io/brickster/reference/lib_jar.md),
[`lib_maven()`](https://databrickslabs.github.io/brickster/reference/lib_maven.md),
[`lib_pypi()`](https://databrickslabs.github.io/brickster/reference/lib_pypi.md),
[`lib_whl()`](https://databrickslabs.github.io/brickster/reference/lib_whl.md)

Other Libraries API:
[`db_libs_all_cluster_statuses()`](https://databrickslabs.github.io/brickster/reference/db_libs_all_cluster_statuses.md),
[`db_libs_cluster_status()`](https://databrickslabs.github.io/brickster/reference/db_libs_cluster_status.md),
[`db_libs_uninstall()`](https://databrickslabs.github.io/brickster/reference/db_libs_uninstall.md)
