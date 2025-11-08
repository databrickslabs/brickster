# Get Status of All Libraries on All Clusters

Get Status of All Libraries on All Clusters

## Usage

``` r
db_libs_all_cluster_statuses(
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

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

A status will be available for all libraries installed on clusters via
the API or the libraries UI as well as libraries set to be installed on
all clusters via the libraries UI.

If a library has been set to be installed on all clusters,
`is_library_for_all_clusters` will be true, even if the library was also
installed on this specific cluster.

## See also

Other Libraries API:
[`db_libs_cluster_status()`](https://databrickslabs.github.io/brickster/reference/db_libs_cluster_status.md),
[`db_libs_install()`](https://databrickslabs.github.io/brickster/reference/db_libs_install.md),
[`db_libs_uninstall()`](https://databrickslabs.github.io/brickster/reference/db_libs_uninstall.md)
