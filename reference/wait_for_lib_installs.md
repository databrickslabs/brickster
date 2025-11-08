# Wait for Libraries to Install on Databricks Cluster

Wait for Libraries to Install on Databricks Cluster

## Usage

``` r
wait_for_lib_installs(
  cluster_id,
  polling_interval = 5,
  allow_failures = FALSE,
  host = db_host(),
  token = db_token()
)
```

## Arguments

- cluster_id:

  Unique identifier of a Databricks cluster.

- polling_interval:

  Number of seconds to wait between status checks

- allow_failures:

  If `FALSE` (default) will error if any libraries status is `FAILED`.
  When `TRUE` any `FAILED` installs will be presented as a warning.

- host:

  Databricks workspace URL, defaults to calling
  [`db_host()`](https://databrickslabs.github.io/brickster/reference/db_host.md).

- token:

  Databricks workspace token, defaults to calling
  [`db_token()`](https://databrickslabs.github.io/brickster/reference/db_token.md).

## Details

Library installs on Databricks clusters are asynchronous, this function
allows you to repeatedly check installation status of each library.

Can be used to block any scripts until required dependencies are
installed.

## See also

[`db_libs_cluster_status()`](https://databrickslabs.github.io/brickster/reference/db_libs_cluster_status.md)
