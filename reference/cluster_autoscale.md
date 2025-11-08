# Cluster Autoscale

Range defining the min and max number of cluster workers.

## Usage

``` r
cluster_autoscale(min_workers, max_workers)
```

## Arguments

- min_workers:

  The minimum number of workers to which the cluster can scale down when
  underutilized. It is also the initial number of workers the cluster
  will have after creation.

- max_workers:

  The maximum number of workers to which the cluster can scale up when
  overloaded. `max_workers` must be strictly greater than `min_workers`.

## See also

[`db_cluster_create()`](https://databrickslabs.github.io/brickster/reference/db_cluster_create.md),
[`db_cluster_edit()`](https://databrickslabs.github.io/brickster/reference/db_cluster_edit.md)
