# Get and Start Cluster

Get and Start Cluster

## Usage

``` r
get_and_start_cluster(
  cluster_id,
  polling_interval = 5,
  host = db_host(),
  token = db_token(),
  silent = FALSE
)
```

## Arguments

- cluster_id:

  Canonical identifier for the cluster.

- polling_interval:

  Number of seconds to wait between status checks

- host:

  Databricks workspace URL, defaults to calling
  [`db_host()`](https://databrickslabs.github.io/brickster/reference/db_host.md).

- token:

  Databricks workspace token, defaults to calling
  [`db_token()`](https://databrickslabs.github.io/brickster/reference/db_token.md).

- silent:

  Boolean (default: `FALSE`), will emit cluster state progress if
  `TRUE`.

## Value

[`db_cluster_get()`](https://databrickslabs.github.io/brickster/reference/db_cluster_get.md)

## Details

Get information regarding a Databricks cluster. If the cluster is
inactive it will be started and wait until the cluster is active.

## See also

[`db_cluster_get()`](https://databrickslabs.github.io/brickster/reference/db_cluster_get.md)
and
[`db_cluster_start()`](https://databrickslabs.github.io/brickster/reference/db_cluster_start.md).

Other Clusters API:
[`db_cluster_create()`](https://databrickslabs.github.io/brickster/reference/db_cluster_create.md),
[`db_cluster_edit()`](https://databrickslabs.github.io/brickster/reference/db_cluster_edit.md),
[`db_cluster_events()`](https://databrickslabs.github.io/brickster/reference/db_cluster_events.md),
[`db_cluster_get()`](https://databrickslabs.github.io/brickster/reference/db_cluster_get.md),
[`db_cluster_list()`](https://databrickslabs.github.io/brickster/reference/db_cluster_list.md),
[`db_cluster_list_node_types()`](https://databrickslabs.github.io/brickster/reference/db_cluster_list_node_types.md),
[`db_cluster_list_zones()`](https://databrickslabs.github.io/brickster/reference/db_cluster_list_zones.md),
[`db_cluster_perm_delete()`](https://databrickslabs.github.io/brickster/reference/db_cluster_perm_delete.md),
[`db_cluster_pin()`](https://databrickslabs.github.io/brickster/reference/db_cluster_pin.md),
[`db_cluster_resize()`](https://databrickslabs.github.io/brickster/reference/db_cluster_resize.md),
[`db_cluster_restart()`](https://databrickslabs.github.io/brickster/reference/db_cluster_restart.md),
[`db_cluster_runtime_versions()`](https://databrickslabs.github.io/brickster/reference/db_cluster_runtime_versions.md),
[`db_cluster_start()`](https://databrickslabs.github.io/brickster/reference/db_cluster_start.md),
[`db_cluster_terminate()`](https://databrickslabs.github.io/brickster/reference/db_cluster_terminate.md),
[`db_cluster_unpin()`](https://databrickslabs.github.io/brickster/reference/db_cluster_unpin.md),
[`get_latest_dbr()`](https://databrickslabs.github.io/brickster/reference/get_latest_dbr.md)

Other Cluster Helpers:
[`get_latest_dbr()`](https://databrickslabs.github.io/brickster/reference/get_latest_dbr.md)
