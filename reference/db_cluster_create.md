# Create a Cluster

Create a Cluster

## Usage

``` r
db_cluster_create(
  name,
  spark_version,
  node_type_id,
  num_workers = NULL,
  autoscale = NULL,
  spark_conf = list(),
  cloud_attrs = aws_attributes(),
  driver_node_type_id = NULL,
  custom_tags = list(),
  init_scripts = list(),
  spark_env_vars = list(),
  autotermination_minutes = 120,
  log_conf = NULL,
  ssh_public_keys = NULL,
  driver_instance_pool_id = NULL,
  instance_pool_id = NULL,
  idempotency_token = NULL,
  enable_elastic_disk = TRUE,
  apply_policy_default_values = TRUE,
  enable_local_disk_encryption = TRUE,
  docker_image = NULL,
  policy_id = NULL,
  kind = c("CLASSIC_PREVIEW"),
  data_security_mode = c("NONE", "SINGLE_USER", "USER_ISOLATION", "LEGACY_TABLE_ACL",
    "LEGACY_PASSTHROUGH", "LEGACY_SINGLE_USER", "LEGACY_SINGLE_USER_STANDARD",
    "DATA_SECURITY_MODE_STANDARD", "DATA_SECURITY_MODE_DEDICATED",
    "DATA_SECURITY_MODE_AUTO"),
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

- name:

  Cluster name requested by the user. This doesn’t have to be unique. If
  not specified at creation, the cluster name will be an empty string.

- spark_version:

  The runtime version of the cluster. You can retrieve a list of
  available runtime versions by using
  [`db_cluster_runtime_versions()`](https://databrickslabs.github.io/brickster/reference/db_cluster_runtime_versions.md).

- node_type_id:

  The node type for the worker nodes.
  [`db_cluster_list_node_types()`](https://databrickslabs.github.io/brickster/reference/db_cluster_list_node_types.md)
  can be used to see available node types.

- num_workers:

  Number of worker nodes that this cluster should have. A cluster has
  one Spark driver and `num_workers` executors for a total of
  `num_workers` + 1 Spark nodes.

- autoscale:

  Instance of
  [`cluster_autoscale()`](https://databrickslabs.github.io/brickster/reference/cluster_autoscale.md).

- spark_conf:

  Named list. An object containing a set of optional, user-specified
  Spark configuration key-value pairs. You can also pass in a string of
  extra JVM options to the driver and the executors via
  `spark.driver.extraJavaOptions` and `spark.executor.extraJavaOptions`
  respectively. E.g.
  `list("spark.speculation" = true, "spark.streaming.ui.retainedBatches" = 5)`.

- cloud_attrs:

  Attributes related to clusters running on specific cloud provider.
  Defaults to
  [`aws_attributes()`](https://databrickslabs.github.io/brickster/reference/aws_attributes.md).
  Must be one of
  [`aws_attributes()`](https://databrickslabs.github.io/brickster/reference/aws_attributes.md),
  [`azure_attributes()`](https://databrickslabs.github.io/brickster/reference/azure_attributes.md),
  [`gcp_attributes()`](https://databrickslabs.github.io/brickster/reference/gcp_attributes.md).

- driver_node_type_id:

  The node type of the Spark driver. This field is optional; if unset,
  the driver node type will be set as the same value as `node_type_id`
  defined above.
  [`db_cluster_list_node_types()`](https://databrickslabs.github.io/brickster/reference/db_cluster_list_node_types.md)
  can be used to see available node types.

- custom_tags:

  Named list. An object containing a set of tags for cluster resources.
  Databricks tags all cluster resources with these tags in addition to
  `default_tags`. Databricks allows at most 45 custom tags.

- init_scripts:

  Instance of
  [`init_script_info()`](https://databrickslabs.github.io/brickster/reference/init_script_info.md).

- spark_env_vars:

  Named list. User-specified environment variable key-value pairs. In
  order to specify an additional set of `SPARK_DAEMON_JAVA_OPTS`, we
  recommend appending them to `$SPARK_DAEMON_JAVA_OPTS` as shown in the
  following example. This ensures that all default Databricks managed
  environmental variables are included as well. E.g.
  `{"SPARK_DAEMON_JAVA_OPTS": "$SPARK_DAEMON_JAVA_OPTS -Dspark.shuffle.service.enabled=true"}`

- autotermination_minutes:

  Automatically terminates the cluster after it is inactive for this
  time in minutes. If not set, this cluster will not be automatically
  terminated. If specified, the threshold must be between 10 and 10000
  minutes. You can also set this value to 0 to explicitly disable
  automatic termination. Defaults to 120.

- log_conf:

  Instance of
  [`cluster_log_conf()`](https://databrickslabs.github.io/brickster/reference/cluster_log_conf.md).

- ssh_public_keys:

  List. SSH public key contents that will be added to each Spark node in
  this cluster. The corresponding private keys can be used to login with
  the user name ubuntu on port 2200. Up to 10 keys can be specified.

- driver_instance_pool_id:

  ID of the instance pool to use for the driver node. You must also
  specify `instance_pool_id`. Optional.

- instance_pool_id:

  ID of the instance pool to use for cluster nodes. If
  `driver_instance_pool_id` is present, `instance_pool_id` is used for
  worker nodes only. Otherwise, it is used for both the driver and
  worker nodes. Optional.

- idempotency_token:

  An optional token that can be used to guarantee the idempotency of
  cluster creation requests. If an active cluster with the provided
  token already exists, the request will not create a new cluster, but
  it will return the ID of the existing cluster instead. The existence
  of a cluster with the same token is not checked against terminated
  clusters. If you specify the idempotency token, upon failure you can
  retry until the request succeeds. Databricks guarantees that exactly
  one cluster will be launched with that idempotency token. This token
  should have at most 64 characters.

- enable_elastic_disk:

  When enabled, this cluster will dynamically acquire additional disk
  space when its Spark workers are running low on disk space.

- apply_policy_default_values:

  Boolean (Default: `TRUE`), whether to use policy default values for
  missing cluster attributes.

- enable_local_disk_encryption:

  Boolean (Default: `TRUE`), whether encryption of disks locally
  attached to the cluster is enabled.

- docker_image:

  Instance of
  [`docker_image()`](https://databrickslabs.github.io/brickster/reference/docker_image.md).

- policy_id:

  String, ID of a cluster policy.

- kind:

  The kind of compute described by this compute specification.

- data_security_mode:

  Data security mode decides what data governance model to use when
  accessing data from a cluster.

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

Create a new Apache Spark cluster. This method acquires new instances
from the cloud provider if necessary. This method is asynchronous; the
returned `cluster_id` can be used to poll the cluster state
([`db_cluster_get()`](https://databrickslabs.github.io/brickster/reference/db_cluster_get.md)).
When this method returns, the cluster is in a `PENDING` state. The
cluster is usable once it enters a `RUNNING` state.

Databricks may not be able to acquire some of the requested nodes, due
to cloud provider limitations or transient network issues. If Databricks
acquires at least 85% of the requested on-demand nodes, cluster creation
will succeed. Otherwise the cluster will terminate with an informative
error message.

Cannot specify both `autoscale` and `num_workers`, must choose one.

[More
Documentation](https://docs.databricks.com/api/workspace/clusters/create).

## See also

Other Clusters API:
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
[`get_and_start_cluster()`](https://databrickslabs.github.io/brickster/reference/get_and_start_cluster.md),
[`get_latest_dbr()`](https://databrickslabs.github.io/brickster/reference/get_latest_dbr.md)
