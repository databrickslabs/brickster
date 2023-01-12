# https://docs.databricks.com/dev-tools/api/latest/clusters.html

#' Create a Cluster
#'
#' @param name Cluster name requested by the user. This doesn’t have to be
#' unique. If not specified at creation, the cluster name will be an empty
#' string.
#' @param spark_version The runtime version of the cluster. You can retrieve a
#' list of available runtime versions by using [db_cluster_runtime_versions()].
#' @param spark_conf Named list. An object containing a set of optional,
#' user-specified Spark configuration key-value pairs. You can also pass in a
#' string of extra JVM options to the driver and the executors via
#' `spark.driver.extraJavaOptions` and `spark.executor.extraJavaOptions`
#' respectively. E.g. `list("spark.speculation" = true,
#' "spark.streaming.ui.retainedBatches" = 5)`.
#' @param num_workers Number of worker nodes that this cluster should have. A
#' cluster has one Spark driver and `num_workers` executors for a total of
#' `num_workers` + 1 Spark nodes.
#' @param autoscale Instance of [cluster_autoscale()].
#' @param node_type_id The node type for the worker nodes.
#' [db_cluster_list_node_types()] can be used to see available node types.
#' @param cloud_attrs Attributes related to clusters running on specific cloud
#' provider. Defaults to [aws_attributes()]. Must be one of [aws_attributes()],
#' [azure_attributes()], [gcp_attributes()].
#' @param driver_node_type_id The node type of the Spark driver. This field is
#' optional; if unset, the driver node type will be set as the same value as
#' `node_type_id` defined above. [db_cluster_list_node_types()] can be used to
#' see available node types.
#' @param custom_tags Named list. An object containing a set of tags for cluster
#' resources. Databricks tags all cluster resources with these tags in addition
#' to `default_tags`. Databricks allows at most 45 custom tags.
#' @param log_conf Instance of [cluster_log_conf()].
#' @param init_scripts Instance of [init_script_info()].
#' @param spark_env_vars Named list. User-specified environment variable
#' key-value pairs. In order to specify an additional set of
#' `SPARK_DAEMON_JAVA_OPTS`, we recommend appending them to
#' `$SPARK_DAEMON_JAVA_OPTS` as shown in the following example. This ensures
#' that all default Databricks managed environmental variables are included as
#' well. E.g. `{"SPARK_DAEMON_JAVA_OPTS": "$SPARK_DAEMON_JAVA_OPTS
#'  -Dspark.shuffle.service.enabled=true"}`
#' @param autotermination_minutes Automatically terminates the cluster after it
#' is inactive for this time in minutes. If not set, this cluster will not be
#' automatically terminated. If specified, the threshold must be between 10 and
#' 10000 minutes. You can also set this value to 0 to explicitly disable
#' automatic termination. Defaults to 120.
#' @param ssh_public_keys List. SSH public key contents that will be added to each
#' Spark node in this cluster. The corresponding private keys can be used to
#' login with the user name ubuntu on port 2200. Up to 10 keys can be specified.
#' @param enable_elastic_disk When enabled, this cluster will dynamically
#' acquire additional disk space when its Spark workers are running low on
#' disk space.
#' @param driver_instance_pool_id ID of the instance pool to use for the
#' driver node. You must also specify `instance_pool_id`. Optional.
#' @param instance_pool_id ID of the instance pool to use for cluster nodes. If
#' `driver_instance_pool_id` is present, `instance_pool_id` is used for worker
#' nodes only. Otherwise, it is used for both the driver and worker nodes.
#' Optional.
#' @param idempotency_token An optional token that can be used to guarantee the
#' idempotency of cluster creation requests. If an active cluster with the
#' provided token already exists, the request will not create a new cluster,
#' but it will return the ID of the existing cluster instead. The existence of a
#' cluster with the same token is not checked against terminated clusters. If
#' you specify the idempotency token, upon failure you can retry until the
#' request succeeds. Databricks guarantees that exactly one cluster will be
#' launched with that idempotency token. This token should have at most 64
#' characters.
#' @param apply_policy_default_values Boolean (Default: `TRUE`), whether to use
#' policy default values for missing cluster attributes.
#' @param enable_local_disk_encryption Boolean (Default: `TRUE`), whether
#' encryption of disks locally attached to the cluster is enabled.
#' @param docker_image Instance of [docker_image()].
#' @param policy_id String, ID of a cluster policy.
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' Create a new Apache Spark cluster. This method acquires new instances from
#' the cloud provider if necessary. This method is asynchronous; the returned
#' `cluster_id` can be used to poll the cluster state ([db_cluster_get()]).
#' When this method returns, the cluster is in a `PENDING` state. The cluster is
#' usable once it enters a `RUNNING` state.
#'
#' Databricks may not be able to acquire some of the requested nodes, due to
#' cloud provider limitations or transient network issues. If Databricks
#' acquires at least 85% of the requested on-demand nodes, cluster creation will
#' succeed. Otherwise the cluster will terminate with an informative error
#' message.
#'
#' Cannot specify both `autoscale` and `num_workers`, must choose one.
#'
#' [More Documentation](https://docs.databricks.com/dev-tools/api/latest/clusters.html#create).
#'
#' @family Clusters API
#'
#' @export
db_cluster_create <- function(name,
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
                              host = db_host(), token = db_token(),
                              perform_request = TRUE) {

  # input checks
  # - cloud_attrs must be of class AwsAttributes/AzureAttributes/GcpAttributes
  # - if specified, log_conf must be of class ClusterLogConf
  # - all values in init_scripts must be from init_script_info() (class: InitScriptInfo)
  # - if specified, docker_image must be of class DockerImage

  body <- list(
    cluster_name = name,
    spark_version = spark_version,
    spark_conf = spark_conf,
    node_type_id = node_type_id,
    driver_node_type_id = driver_node_type_id,
    custom_tags = custom_tags,
    log_conf = log_conf,
    init_scripts = init_scripts,
    spark_env_vars = spark_env_vars,
    autotermination_minutes = autotermination_minutes,
    ssh_public_keys = ssh_public_keys,
    enable_elastic_disk = enable_elastic_disk,
    driver_instance_pool_id = driver_instance_pool_id,
    instance_pool_id = instance_pool_id,
    idempotency_token = idempotency_token,
    apply_policy_default_values = apply_policy_default_values,
    enable_local_disk_encryption = enable_local_disk_encryption,
    docker_image = docker_image,
    policy_id = policy_id
  )

  if (is.null(num_workers)) {
    stopifnot(is.cluster_autoscale(autoscale))
    body[["autoscale"]] <- unclass(autoscale)
  } else {
    body[["num_workers"]] <- num_workers
  }

  if (is.aws_attributes(cloud_attrs)) {
    body[["aws_attributes"]] <- unclass(cloud_attrs)
  } else if (is.azure_attributes(cloud_attrs)) {
    body[["azure_attributes"]] <- unclass(cloud_attrs)
  } else if (is.gcp_attributes(cloud_attrs)) {
    body[["gcp_attributes"]] <- unclass(cloud_attrs)
  } else {
    stop("Please use `aws_attributes()`, `azure_attributes()`, or `gcp_attributes()` to specify `cloud_attr`")
  }

  req <- db_request(
    endpoint = "clusters/create",
    method = "POST",
    version = "2.0",
    body = body,
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }

}

#' Edit a Cluster
#'
#' Edit the configuration of a cluster to match the provided attributes and
#' size.
#'
#' @param cluster_id Canonical identifier for the cluster.
#' @inheritParams auth_params
#' @inheritParams db_cluster_create
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' You can edit a cluster if it is in a `RUNNING` or `TERMINATED` state. If you
#' edit a cluster while it is in a `RUNNING` state, it will be restarted so that
#' the new attributes can take effect. If you edit a cluster while it is in a
#' `TERMINATED` state, it will remain `TERMINATED.` The next time it is started
#' using the clusters/start API, the new attributes will take effect. An attempt
#' to edit a cluster in any other state will be rejected with an `INVALID_STATE`
#' error code.
#'
#' Clusters created by the Databricks Jobs service cannot be edited.
#'
#' @family Clusters API
#'
#' @export
db_cluster_edit <- function(cluster_id,
                            spark_version,
                            node_type_id,
                            num_workers = NULL,
                            autoscale = NULL,
                            name = NULL,
                            spark_conf = NULL,
                            cloud_attrs = NULL,
                            driver_node_type_id = NULL,
                            custom_tags = NULL,
                            init_scripts = NULL,
                            spark_env_vars = NULL,
                            autotermination_minutes = NULL,
                            log_conf = NULL,
                            ssh_public_keys = NULL,
                            driver_instance_pool_id = NULL,
                            instance_pool_id = NULL,
                            idempotency_token = NULL,
                            enable_elastic_disk = NULL,
                            apply_policy_default_values = NULL,
                            enable_local_disk_encryption = NULL,
                            docker_image = NULL,
                            policy_id = NULL,
                            host = db_host(), token = db_token(),
                            perform_request = TRUE) {

  # NOTES:
  # edit is annoying and requires node size/spark version for edit even if
  # they aren't being changed from existing config

  # input checks
  # - cloud_attrs must be of class AwsAttributes or AzureAttributes
  # - if specified, log_conf must be of class ClusterLogConf
  # - all values in init_scripts must be from init_script_info() (class: InitScriptInfo)
  # - if specified, docker_image must be of class DockerImage

  body <- list(
    cluster_id = cluster_id,
    cluster_name = name,
    spark_version = spark_version,
    spark_conf = spark_conf,
    node_type_id = node_type_id,
    driver_node_type_id = driver_node_type_id,
    custom_tags = custom_tags,
    log_conf = log_conf,
    init_scripts = init_scripts,
    spark_env_vars = spark_env_vars,
    autotermination_minutes = autotermination_minutes,
    ssh_public_keys = ssh_public_keys,
    enable_elastic_disk = enable_elastic_disk,
    driver_instance_pool_id = driver_instance_pool_id,
    instance_pool_id = instance_pool_id,
    idempotency_token = idempotency_token,
    apply_policy_default_values = apply_policy_default_values,
    enable_local_disk_encryption = enable_local_disk_encryption,
    docker_image = docker_image,
    policy_id = policy_id
  )

  if (!(is.null(num_workers) && is.null(autoscale))) {
    if (is.null(num_workers)) {
      stopifnot(is.cluster_autoscale(autoscale))
      body[["autoscale"]] <- unclass(autoscale)
    } else {
      body[["num_workers"]] <- num_workers
    }
  }

  if (!is.null(cloud_attrs)) {
    if (is.aws_attributes(cloud_attrs)) {
      body[["aws_attributes"]] <- unclass(cloud_attrs)
    } else if (is.azure_attributes(cloud_attrs)) {
      body[["azure_attributes"]] <- unclass(cloud_attrs)
    } else {
      stop("Please use `aws_attributes()` or `azure_attributes()` to specify `cloud_attr`")
    }
  }

  body <- purrr::discard(body, is.null)

  req <- db_request(
    endpoint = "clusters/edit",
    method = "POST",
    version = "2.0",
    body = body,
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }

}

#' Cluster Action Helper Function
#'
#' @param action One of `start`, `restart`, `delete`, `permanent-delete`, `pin`,
#' `unpin`.
#' @inheritParams auth_params
#' @inheritParams db_cluster_edit
#' @inheritParams db_sql_warehouse_create
db_cluster_action <- function(cluster_id,
                              action = c("start", "restart", "delete", "permanent-delete", "pin", "unpin"),
                              host = db_host(), token = db_token(),
                              perform_request = TRUE) {
  body <- list(
    cluster_id = cluster_id
  )

  req <- db_request(
    endpoint = paste0("clusters/", action),
    method = "POST",
    version = "2.0",
    body = body,
    host = host,
    token = token
  )

  req <- req %>%
    httr2::req_body_json(body)

  if (perform_request) {
    httr2::req_perform(req)
    NULL
  } else {
    req
  }

}

#' Start a Cluster
#'
#' @inheritParams auth_params
#' @inheritParams db_cluster_edit
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' Start a terminated cluster given its ID.
#'
#' This is similar to [db_cluster_create()], except:
#' * The terminated cluster ID and attributes are preserved.
#' * The cluster starts with the last specified cluster size. If the terminated
#' cluster is an autoscaling cluster, the cluster starts with the minimum number
#' of nodes.
#' * If the cluster is in the `RESTARTING` state, a `400` error is returned.
#' * You cannot start a cluster launched to run a job.
#'
#' @family Clusters API
#'
#' @export
db_cluster_start <- function(cluster_id,
                             host = db_host(), token = db_token(),
                             perform_request = TRUE) {
  db_cluster_action(cluster_id, "start", host, token, perform_request)
}

#' Restart a Cluster
#'
#' @inheritParams auth_params
#' @inheritParams db_cluster_edit
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' The cluster must be in the `RUNNING` state.
#'
#' @family Clusters API
#'
#' @export
db_cluster_restart <- function(cluster_id,
                               host = db_host(), token = db_token(),
                               perform_request = TRUE) {
  db_cluster_action(cluster_id, "restart", host, token, perform_request)
}

#' Delete/Terminate a Cluster
#'
#' @inheritParams auth_params
#' @inheritParams db_cluster_edit
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' The cluster is removed asynchronously. Once the termination has completed,
#' the cluster will be in the `TERMINATED` state. If the cluster is already in a
#' `TERMINATING` or `TERMINATED` state, nothing will happen.
#'
#' Unless a cluster is pinned, 30 days after the cluster is terminated, it is
#' permanently deleted.
#'
#' @family Clusters API
#'
#' @export
db_cluster_delete <- function(cluster_id,
                              host = db_host(), token = db_token(),
                              perform_request = TRUE) {
  db_cluster_action(cluster_id, "delete", host, token, perform_request)
}

#' Permanently Delete a Cluster
#'
#' @inheritParams auth_params
#' @inheritParams db_cluster_edit
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' If the cluster is running, it is terminated and its resources are
#' asynchronously removed. If the cluster is terminated, then it is immediately
#' removed.
#'
#' You cannot perform *any action, including retrieve the cluster’s permissions,
#' on a permanently deleted cluster. A permanently deleted cluster is also no
#' longer returned in the cluster list.
#'
#' @family Clusters API
#'
#' @export
db_cluster_perm_delete <- function(cluster_id,
                                   host = db_host(), token = db_token(),
                                   perform_request = TRUE) {
  db_cluster_action(cluster_id, "permanent-delete", host, token, perform_request)
}

#' Pin a Cluster
#'
#' @inheritParams auth_params
#' @inheritParams db_cluster_edit
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' Ensure that an all-purpose cluster configuration is retained even after a
#' cluster has been terminated for more than 30 days. Pinning ensures that the
#' cluster is always returned by [db_cluster_list()]. Pinning a cluster that is
#' already pinned has no effect.
#'
#' @family Clusters API
#'
#' @export
db_cluster_pin <- function(cluster_id,
                           host = db_host(), token = db_token(),
                           perform_request = TRUE) {
  db_cluster_action(cluster_id, "pin", host, token, perform_request)
}

#' Unpin a Cluster
#'
#' @inheritParams auth_params
#' @inheritParams db_cluster_edit
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' Allows the cluster to eventually be removed from the list returned by
#' [db_cluster_list()]. Unpinning a cluster that is not pinned has no effect.
#'
#' @family Clusters API
#'
#' @export
db_cluster_unpin <- function(cluster_id,
                             host = db_host(), token = db_token(),
                             perform_request = TRUE) {
  db_cluster_action(cluster_id, "unpin", host, token, perform_request)
}

#' Resize a Cluster
#'
#' @inheritParams auth_params
#' @inheritParams db_cluster_edit
#' @inheritParams db_sql_warehouse_create
#'
#' @details The cluster must be in the `RUNNING` state.
#'
#' @family Clusters API
#'
#' @export
db_cluster_resize <- function(cluster_id, num_workers = NULL, autoscale = NULL,
                              host = db_host(), token = db_token(),
                              perform_request = TRUE) {
  if (is.null(num_workers) && is.null(autoscale)) {
    stop("Must specify one of `num_workers` or `autoscale`.")
  }

  body <- list(
    cluster_id = cluster_id
  )

  if (is.null(num_workers)) {
    stopifnot(is.cluster_autoscale(autoscale))
    body[["autoscale"]] <- unclass(autoscale)
  } else {
    body[["num_workers"]] <- num_workers
  }

  req <- db_request(
    endpoint = "clusters/resize",
    method = "POST",
    version = "2.0",
    body = body,
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }

}

#' Get Details of a Cluster
#'
#' @inheritParams auth_params
#' @inheritParams db_cluster_edit
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' Retrieve the information for a cluster given its identifier. Clusters can be
#' described while they are running or up to 30 days after they are terminated.
#'
#' @family Clusters API
#'
#' @export
db_cluster_get <- function(cluster_id,
                           host = db_host(), token = db_token(),
                           perform_request = TRUE) {
  body <- list(
    cluster_id = cluster_id
  )

  req <- db_request(
    endpoint = "clusters/get",
    method = "GET",
    version = "2.0",
    body = body,
    host = host,
    token = token
  )

  req <- req %>%
    httr2::req_body_json(body)

  if (perform_request) {
    req %>%
      httr2::req_perform() %>%
      httr2::resp_body_json()
  } else {
    req
  }

}

#' List Clusters
#'
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' Return information about all pinned clusters, active clusters, up to 150 of
#' the most recently terminated all-purpose clusters in the past 30 days, and up
#' to 30 of the most recently terminated job clusters in the past 30 days.
#'
#' For example, if there is 1 pinned cluster, 4 active clusters, 45 terminated
#' all-purpose clusters in the past 30 days, and 50 terminated job clusters in
#' the past 30 days, then this API returns:
#' * the 1 pinned cluster
#' * 4 active clusters
#' * All 45 terminated all-purpose clusters
#' * The 30 most recently terminated job clusters
#'
#' @family Clusters API
#'
#' @export
db_cluster_list <- function(host = db_host(), token = db_token(),
                            perform_request = TRUE) {
  req <- db_request(
    endpoint = "clusters/list",
    method = "GET",
    version = "2.0",
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)$clusters
  } else {
    req
  }
}

#' List Available Cluster Node Types
#'
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' Return a list of supported Spark node types. These node types can be used to
#' launch a cluster.
#'
#' @family Clusters API
#'
#' @export
db_cluster_list_node_types <- function(host = db_host(), token = db_token(),
                                       perform_request = TRUE) {
  req <- db_request(
    endpoint = "clusters/list-node-types",
    method = "GET",
    version = "2.0",
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }

}

#' List Available Databricks Runtime Versions
#'
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' Return the list of available runtime versions. These versions can be used to
#' launch a cluster.
#'
#' @family Clusters API
#'
#' @export
db_cluster_runtime_versions <- function(host = db_host(), token = db_token(),
                                        perform_request = TRUE) {
  req <- db_request(
    endpoint = "clusters/spark-versions",
    method = "GET",
    version = "2.0",
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }

}

#' List Availability Zones (AWS Only)
#'
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @family Clusters API
#'
#' @details
#' **Amazon Web Services (AWS) ONLY!**
#' Return a list of availability zones where clusters can be created in
#' (ex: us-west-2a). These zones can be used to launch a cluster.
#'
#' @export
db_cluster_list_zones <- function(host = db_host(), token = db_token(),
                                  perform_request = TRUE) {
  req <- db_request(
    endpoint = "clusters/list-zones",
    method = "GET",
    version = "2.0",
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }

}

#' List Cluster Activity Events
#'
#' @param cluster_id The ID of the cluster to retrieve events about.
#' @param start_time The start time in epoch milliseconds. If empty, returns
#' events starting from the beginning of time.
#' @param end_time The end time in epoch milliseconds. If empty, returns events
#' up to the current time.
#' @param event_types List. Optional set of event types to filter by. Default
#' is to return all events. [Event Types](https://docs.databricks.com/dev-tools/api/latest/clusters.html#clustereventtype).
#' @param order Either `DESC` (default) or `ASC`.
#' @param offset The offset in the result set. Defaults to 0 (no offset). When
#' an offset is specified and the results are requested in descending order, the
#' end_time field is required.
#' @param limit Maximum number of events to include in a page of events.
#' Defaults to 50, and maximum allowed value is 500.
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' Retrieve a list of events about the activity of a cluster. You can retrieve
#' events from active clusters (running, pending, or reconfiguring) and
#' terminated clusters within 30 days of their last termination. This API is
#' paginated. If there are more events to read, the response includes all the
#' parameters necessary to request the next page of events.
#'
#' @family Clusters API
#'
#' @export
db_cluster_events <- function(cluster_id,
                              start_time = NULL, end_time = NULL,
                              event_types = NULL,
                              order = c("DESC", "ASC"), offset = 0, limit = 50,
                              host = db_host(), token = db_token(),
                              perform_request = TRUE) {

  order <- match.arg(order, several.ok = FALSE)
  stopifnot(
    offset >= 0,
    limit > 0 && limit <= 500
  )

  body <- list(
    cluster_id = cluster_id,
    start_time = as.integer(start_time),
    end_time = as.integer(end_time),
    order = order,
    offset = as.integer(offset),
    limit = as.integer(limit)
  )

  req <- db_request(
    endpoint = "clusters/events",
    method = "POST",
    version = "2.0",
    body = body,
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)$events
  } else {
    req
  }

}

### Higher Functions ###########################################################

#' Get and Start Cluster
#'
#' @param polling_interval Number of seconds to wait between status checks
#' @inheritParams auth_params
#' @inheritParams db_cluster_edit
#'
#' @details Get information regarding a Databricks cluster. If the cluster is
#' inactive it will be started and wait until the cluster is active.
#'
#' @seealso [db_cluster_get()] and [db_cluster_start()].
#'
#' @family Clusters API
#' @family Cluster Helpers
#'
#' @return `db_cluster_get()`
#' @export
get_and_start_cluster <- function(cluster_id, polling_interval = 5,
                                  host = db_host(), token = db_token()) {

  # get cluster status
  cluster_status <- db_cluster_get(cluster_id = cluster_id, host = host, token = token)

  # if the cluster isn't running, start it
  if (!cluster_status$state %in% c("RUNNING", "PENDING")) {
    db_cluster_start(cluster_id = cluster_id, host = host, token = token)
  }

  # wait for cluster to become active
  while (cluster_status$state != "RUNNING") {
    Sys.sleep(polling_interval)
    cluster_status <- db_cluster_get(cluster_id = cluster_id, host = host, token = token)
  }

  cluster_status
}
