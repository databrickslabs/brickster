# Delete/Terminate a Cluster

Delete/Terminate a Cluster

## Usage

``` r
db_cluster_delete(
  cluster_id,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

- cluster_id:

  Canonical identifier for the cluster.

- host:

  Databricks workspace URL, defaults to calling
  [`db_host()`](https://databrickslabs.github.io/brickster/reference/db_host.md).

- token:

  Databricks workspace token, defaults to calling
  [`db_token()`](https://databrickslabs.github.io/brickster/reference/db_token.md).

- perform_request:

  If `TRUE` (default) the request is performed, if `FALSE` the httr2
  request is returned *without* being performed.

## Value

If `perform_request = TRUE`, returns endpoint-specific API output. If
`FALSE`, returns an `httr2_request`.

## Details

The cluster must be in the `RUNNING` state.
