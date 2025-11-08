# New Cluster

New Cluster

## Usage

``` r
new_cluster(
  num_workers,
  spark_version,
  node_type_id,
  driver_node_type_id = NULL,
  autoscale = NULL,
  cloud_attrs = NULL,
  spark_conf = NULL,
  spark_env_vars = NULL,
  custom_tags = NULL,
  ssh_public_keys = NULL,
  log_conf = NULL,
  init_scripts = NULL,
  enable_elastic_disk = TRUE,
  driver_instance_pool_id = NULL,
  instance_pool_id = NULL,
  kind = c("CLASSIC_PREVIEW"),
  data_security_mode = c("NONE", "SINGLE_USER", "USER_ISOLATION", "LEGACY_TABLE_ACL",
    "LEGACY_PASSTHROUGH", "LEGACY_SINGLE_USER", "LEGACY_SINGLE_USER_STANDARD",
    "DATA_SECURITY_MODE_STANDARD", "DATA_SECURITY_MODE_DEDICATED",
    "DATA_SECURITY_MODE_AUTO")
)
```

## Arguments

- num_workers:

  Number of worker nodes that this cluster should have. A cluster has
  one Spark driver and `num_workers` executors for a total of
  `num_workers` + 1 Spark nodes.

- spark_version:

  The runtime version of the cluster. You can retrieve a list of
  available runtime versions by using
  [`db_cluster_runtime_versions()`](https://databrickslabs.github.io/brickster/reference/db_cluster_runtime_versions.md).

- node_type_id:

  The node type for the worker nodes.
  [`db_cluster_list_node_types()`](https://databrickslabs.github.io/brickster/reference/db_cluster_list_node_types.md)
  can be used to see available node types.

- driver_node_type_id:

  The node type of the Spark driver. This field is optional; if unset,
  the driver node type will be set as the same value as `node_type_id`
  defined above.
  [`db_cluster_list_node_types()`](https://databrickslabs.github.io/brickster/reference/db_cluster_list_node_types.md)
  can be used to see available node types.

- autoscale:

  Instance of
  [`cluster_autoscale()`](https://databrickslabs.github.io/brickster/reference/cluster_autoscale.md).

- cloud_attrs:

  Attributes related to clusters running on specific cloud provider.
  Defaults to
  [`aws_attributes()`](https://databrickslabs.github.io/brickster/reference/aws_attributes.md).
  Must be one of
  [`aws_attributes()`](https://databrickslabs.github.io/brickster/reference/aws_attributes.md),
  [`azure_attributes()`](https://databrickslabs.github.io/brickster/reference/azure_attributes.md),
  [`gcp_attributes()`](https://databrickslabs.github.io/brickster/reference/gcp_attributes.md).

- spark_conf:

  Named list. An object containing a set of optional, user-specified
  Spark configuration key-value pairs. You can also pass in a string of
  extra JVM options to the driver and the executors via
  `spark.driver.extraJavaOptions` and `spark.executor.extraJavaOptions`
  respectively. E.g.
  `list("spark.speculation" = true, "spark.streaming.ui.retainedBatches" = 5)`.

- spark_env_vars:

  Named list. User-specified environment variable key-value pairs. In
  order to specify an additional set of `SPARK_DAEMON_JAVA_OPTS`, we
  recommend appending them to `$SPARK_DAEMON_JAVA_OPTS` as shown in the
  following example. This ensures that all default Databricks managed
  environmental variables are included as well. E.g.
  `{"SPARK_DAEMON_JAVA_OPTS": "$SPARK_DAEMON_JAVA_OPTS -Dspark.shuffle.service.enabled=true"}`

- custom_tags:

  Named list. An object containing a set of tags for cluster resources.
  Databricks tags all cluster resources with these tags in addition to
  `default_tags`. Databricks allows at most 45 custom tags.

- ssh_public_keys:

  List. SSH public key contents that will be added to each Spark node in
  this cluster. The corresponding private keys can be used to login with
  the user name ubuntu on port 2200. Up to 10 keys can be specified.

- log_conf:

  Instance of
  [`cluster_log_conf()`](https://databrickslabs.github.io/brickster/reference/cluster_log_conf.md).

- init_scripts:

  Instance of
  [`init_script_info()`](https://databrickslabs.github.io/brickster/reference/init_script_info.md).

- enable_elastic_disk:

  When enabled, this cluster will dynamically acquire additional disk
  space when its Spark workers are running low on disk space.

- driver_instance_pool_id:

  ID of the instance pool to use for the driver node. You must also
  specify `instance_pool_id`. Optional.

- instance_pool_id:

  ID of the instance pool to use for cluster nodes. If
  `driver_instance_pool_id` is present, `instance_pool_id` is used for
  worker nodes only. Otherwise, it is used for both the driver and
  worker nodes. Optional.

- kind:

  The kind of compute described by this compute specification.

- data_security_mode:

  Data security mode decides what data governance model to use when
  accessing data from a cluster.

## See also

[`job_task()`](https://databrickslabs.github.io/brickster/reference/job_task.md)

Other Task Objects:
[`condition_task()`](https://databrickslabs.github.io/brickster/reference/condition_task.md),
[`email_notifications()`](https://databrickslabs.github.io/brickster/reference/email_notifications.md),
[`for_each_task()`](https://databrickslabs.github.io/brickster/reference/for_each_task.md),
[`libraries()`](https://databrickslabs.github.io/brickster/reference/libraries.md),
[`notebook_task()`](https://databrickslabs.github.io/brickster/reference/notebook_task.md),
[`pipeline_task()`](https://databrickslabs.github.io/brickster/reference/pipeline_task.md),
[`python_wheel_task()`](https://databrickslabs.github.io/brickster/reference/python_wheel_task.md),
[`run_job_task()`](https://databrickslabs.github.io/brickster/reference/run_job_task.md),
[`spark_jar_task()`](https://databrickslabs.github.io/brickster/reference/spark_jar_task.md),
[`spark_python_task()`](https://databrickslabs.github.io/brickster/reference/spark_python_task.md),
[`spark_submit_task()`](https://databrickslabs.github.io/brickster/reference/spark_submit_task.md),
[`sql_file_task()`](https://databrickslabs.github.io/brickster/reference/sql_file_task.md),
[`sql_query_task()`](https://databrickslabs.github.io/brickster/reference/sql_query_task.md)
