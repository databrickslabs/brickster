# Cluster Management

[brickster](https://github.com/databrickslabs/brickster) has 1:1
mappings with the clusters REST API, enabling full control of Databricks
clusters from your R session.

## Cluster Creation

Clusters have a number of parameters and can be configured to match to
needs of a given workload.
[`db_cluster_create()`](https://databrickslabs.github.io/brickster/reference/db_cluster_create.md)
facilitates creation of a cluster in a Databricks workspace for all
cloud platforms (AWS, Azure, GCP).

Depending on the cloud you will need to change the node types and
`cloud_attrs` to be one of;
[`aws_attributes()`](https://databrickslabs.github.io/brickster/reference/aws_attributes.md),
[`azure_attributes()`](https://databrickslabs.github.io/brickster/reference/azure_attributes.md),
or
[`gcp_attributes()`](https://databrickslabs.github.io/brickster/reference/gcp_attributes.md).

Below we will create a cluster on AWS and then step through using the
other supporting functions.

``` r
library(brickster)

# create a small cluster on AWS with DBR 9.1 LTS
new_cluster <- db_cluster_create(
  name = "brickster-cluster",
  spark_version = "9.1.x-scala2.12",
  num_workers = 2,
  node_type_id = "m5a.xlarge",
  cloud_attrs = aws_attributes(
    ebs_volume_count = 3,
    ebs_volume_size = 100
  )
)
```

Refer to documentation for details on how to use other parameters not
mentioned here (e.g. `spark_conf`).

Before creating a cluster you may want to check the supported values for
a number of the parameters. There are functions to assist with this:

|                                                                                                               Function | Purpose                                                                                                                      |
|-----------------------------------------------------------------------------------------------------------------------:|------------------------------------------------------------------------------------------------------------------------------|
| [`db_cluster_runtime_versions()`](https://databrickslabs.github.io/brickster/reference/db_cluster_runtime_versions.md) | List of runtime versions available for the workspace, useful for finding relevant `spark_version`                            |
|   [`db_cluster_list_node_types()`](https://databrickslabs.github.io/brickster/reference/db_cluster_list_node_types.md) | List of supported node types available in workspace/region, useful for finding relevant `node_type_id`/`driver_node_type_id` |
|             [`db_cluster_list_zones()`](https://databrickslabs.github.io/brickster/reference/db_cluster_list_zones.md) | AWS Only, lists availability zones (AZ) clusters can occupy                                                                  |

[`db_cluster_get()`](https://databrickslabs.github.io/brickster/reference/db_cluster_get.md)
will provide details for the cluster we just created, including
information such as the state.

This can be useful as you may wish to wait for the cluster to be
`RUNNING` , which is exactly what
[`get_and_start_cluster()`](https://databrickslabs.github.io/brickster/reference/get_and_start_cluster.md)
uses internally to wait until the cluster is running before completing.

``` r
cluster_info <- db_cluster_get(cluster_id = new_cluster$cluster_id)
cluster_info$state
```

## Editing Clusters

You can edit Databricks clusters to change various parameters using
[`db_cluster_edit()`](https://databrickslabs.github.io/brickster/reference/db_cluster_edit.md).
For example, we may decide we want our cluster to autoscale between 2-8
nodes and add some tags.

``` r

# we are required to input all parameters
db_cluster_edit(
  cluster_id = new_cluster$cluster_id,
  name = "brickster-cluster",
  spark_version = "9.1.x-scala2.12",
  node_type_id = "m5a.xlarge",
  autoscale = cluster_autoscale(min_workers = 2, max_workers = 8),
  cloud_attrs = aws_attributes(
    ebs_volume_count = 3,
    ebs_volume_size = 100
  ),
  custom_tags = list(
    purpose = "brickster_cluster_demo"
  )
)
```

However, if the intention was to only change the size of a given cluster
the
[`db_cluster_resize()`](https://databrickslabs.github.io/brickster/reference/db_cluster_resize.md)
function is a simpler alternative.

I can either adjust the number of workers or change the autoscale range.
If the range or workers is adjusted via `autoscale` the number of
workers active on the cluster will be increased/decreased if they are
outside the bounds.

``` r
# adjust number autoscale range to be between 4-6 workers
db_cluster_resize(
  cluster_id = new_cluster$cluster_id,
  autoscale = cluster_autoscale(min_workers = 4, max_workers = 6)
)
```

It’s important to note that if specifying `num_workers` instead of
`autoscale` on a cluster than has an existing autoscale range it will
become a fixed number of workers from that point onward.

Databricks clusters can be “pinned” which stops them from being removed
after 30 days of termination.
[`db_cluster_pin()`](https://databrickslabs.github.io/brickster/reference/db_cluster_pin.md)
and
[`db_cluster_unpin()`](https://databrickslabs.github.io/brickster/reference/db_cluster_unpin.md)
are the functions used for changing if a cluster is “pinned” or not.

``` r
# pin the cluster
db_cluster_pin(cluster_id = new_cluster$cluster_id)

# unpin the cluster
# db_cluster_unpin(cluster_id = new_cluster$cluster_id)
```

## Cluster State

There are a few functions that can be used to to manage the state of an
existing cluster

|                                                                                                                                                                                                     Function | Purpose                                                                                      |
|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------:|----------------------------------------------------------------------------------------------|
|                                                                                                             [`db_cluster_start()`](https://databrickslabs.github.io/brickster/reference/db_cluster_start.md) | Start a cluster that is inactive                                                             |
|                                                                                                         [`db_cluster_restart()`](https://databrickslabs.github.io/brickster/reference/db_cluster_restart.md) | Restart a cluster, cluster must already be running                                           |
| [`db_cluster_delete()`](https://databrickslabs.github.io/brickster/reference/db_cluster_delete.md) /[`db_cluster_terminate()`](https://databrickslabs.github.io/brickster/reference/db_cluster_terminate.md) | Terminate an active cluster, does not remove the cluster configuration from Databricks       |
|                                                                                                 [`db_cluster_perm_delete()`](https://databrickslabs.github.io/brickster/reference/db_cluster_perm_delete.md) | Stops (if active) and permanently deletes a cluster, it will not longer appear in Databricks |

## Cluster Libraries

Databricks clusters can have libraries installed from a number of
sources using
[`db_libs_install()`](https://databrickslabs.github.io/brickster/reference/db_libs_install.md)
and the associated `libs_*()` functions:

|                                                                           Function | Library Source      |
|-----------------------------------------------------------------------------------:|---------------------|
|   [`lib_cran()`](https://databrickslabs.github.io/brickster/reference/lib_cran.md) | CRAN                |
|   [`lib_pypi()`](https://databrickslabs.github.io/brickster/reference/lib_pypi.md) | PyPi                |
|     [`lib_egg()`](https://databrickslabs.github.io/brickster/reference/lib_egg.md) | Python egg (file)   |
|     [`lib_whl()`](https://databrickslabs.github.io/brickster/reference/lib_whl.md) | Python wheel (file) |
| [`lib_maven()`](https://databrickslabs.github.io/brickster/reference/lib_maven.md) | Maven               |
|     [`lib_jar()`](https://databrickslabs.github.io/brickster/reference/lib_jar.md) | JAR (file)          |

``` r
# installing a package from CRAN on cluster
db_libs_install(
  cluster_id = new_cluster$cluster_id,
  libraries = libraries(
    lib_cran(package = "palmerpenguins"),
    lib_cran(package = "dplyr")
  )
)
```

For convenience the
[`wait_for_lib_installs()`](https://databrickslabs.github.io/brickster/reference/wait_for_lib_installs.md)
function will block until all the libraries for the specified cluster
have finished installing.

``` r
wait_for_lib_installs(cluster_id = new_cluster$cluster_id)
```

Installation of libraries is asynchronous and will complete in the
background.
[`db_libs_cluster_status()`](https://databrickslabs.github.io/brickster/reference/db_libs_cluster_status.md)
is used to check on the installation status of libraries for a given
cluster,
[`db_libs_all_cluster_statuses()`](https://databrickslabs.github.io/brickster/reference/db_libs_all_cluster_statuses.md)
is used for getting the status of all libraries across all clusters in
the workspace.

``` r
db_libs_cluster_status(cluster_id = new_cluster$cluster_id)
```

Libraries can be uninstalled using
[`db_libs_uninstall()`](https://databrickslabs.github.io/brickster/reference/db_libs_uninstall.md).

``` r
db_libs_uninstall(
  cluster_id = new_cluster$cluster_id,
  libraries = libraries(
    lib_cran(package = "palmerpenguins")
  )
)
```

Using
[`db_libs_cluster_status()`](https://databrickslabs.github.io/brickster/reference/db_libs_cluster_status.md)
shows that the library will be uninstalled upon restart
(e.g. [`db_cluster_restart()`](https://databrickslabs.github.io/brickster/reference/db_cluster_restart.md)).

``` r
db_libs_cluster_status(cluster_id = new_cluster$cluster_id)
```

## Events

A list of events regarding the clusters activity can be fetched via
[`db_cluster_events()`](https://databrickslabs.github.io/brickster/reference/db_cluster_events.md).
There are many [event
types](https://docs.databricks.com/api/workspace/clusters/events#events)
that can occur, and by default the 50 most recent events are returned.

``` r
events <- db_cluster_events(cluster_id = new_cluster$cluster_id)
head(events, 1)
```
