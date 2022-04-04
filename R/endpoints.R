# https://docs.databricks.com/sql/api/sql-endpoints.html

#' Create SQL Endpoint
#'
#' @param name Name of the SQL endpoint. Must be unique.
#' @param cluster_size Size of the clusters allocated to the endpoint. One of
#' `2X-Small`, `X-Small`, `Small`, `Medium`, `Large`, `X-Large`, `2X-Large`,
#' `3X-Large`, `4X-Large`.
#' @param min_num_clusters Minimum number of clusters available when a SQL
#' endpoint is running. The default is 1.
#' @param max_num_clusters Maximum number of clusters available when a SQL
#' endpoint is running. If multi-cluster load balancing is not enabled,
#' this is limited to 1.
#' @param auto_stop_mins Time in minutes until an idle SQL endpoint terminates
#' all clusters and stops. Defaults to 30. For Serverless SQL endpoints
#' (`enable_serverless_compute` = `TRUE`), set this to 10.
#' @param tags Named list that describes the endpoint. Databricks tags all
#' endpoint resources with these tags.
#' @param spot_instance_policy The spot policy to use for allocating instances
#' to clusters. This field is not used if the SQL endpoint is a Serverless SQL
#' endpoint.
#' @param enable_photon Whether queries are executed on a native vectorized
#' engine that speeds up query execution. The default is `TRUE`.
#' @param enable_serverless_compute Whether this SQL endpoint is a Serverless
#' endpoint. To use a Serverless SQL endpoint, you must enable Serverless SQL
#' endpoints for the workspace. If Serverless SQL endpoints are disabled for the
#' workspace, the default is `FALSE` If Serverless SQL endpoints are enabled for
#' the workspace, the default is `TRUE`.
#' @param channel Whether to use the current SQL endpoint compute version or the
#' preview version. Databricks does not recommend using preview versions for
#' production workloads. The default is `CHANNEL_NAME_CURRENT.`
#' @param perform_request If `TRUE` (default) the request is performed, if
#' `FALSE` the httr2 request is returned *without* being performed.
#'
#' @inheritParams auth_params
#'
#' @family SQL Endpoints API
#'
#' @export
db_sql_endpoint_create <- function(name,
                                   cluster_size,
                                   min_num_clusters = 1,
                                   max_num_clusters = 1,
                                   auto_stop_mins = 30,
                                   tags = list(),
                                   spot_instance_policy = c("COST_OPTIMIZED", "RELIABILITY_OPTIMIZED"),
                                   enable_photon = TRUE,
                                   enable_serverless_compute = NULL,
                                   channel = c("CHANNEL_NAME_CURRENT", "CHANNEL_NAME_PREVIEW"),
                                   host = db_host(), token = db_token(),
                                   perform_request = TRUE) {

  # checks
  spot_instance_policy <- match.arg(spot_instance_policy, several.ok = FALSE)
  channel <- match.arg(channel, several.ok = FALSE)
  sizes <- c(
    "2X-Small", "X-Small", "Small",
    "Medium", "Large", "X-Large",
    "2X-Large", "3X-Large", "4X-Large"
  )
  stopifnot(cluster_size %in% sizes)

  body <- list(
    name = name,
    cluster_size = cluster_size,
    min_num_clusters = min_num_clusters,
    max_num_clusters = max_num_clusters,
    auto_stop_mins = auto_stop_mins,
    spot_instance_policy = spot_instance_policy,
    enable_photon = enable_photon,
    enable_serverless_compute = enable_serverless_compute,
    channel = list(name = channel)
  )

  req <- db_request(
    endpoint = "sql/endpoints",
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

#' Delete SQL Endpoint
#'
#' @param id ID of the SQL endpoint.
#' @inheritParams auth_params
#' @inheritParams db_sql_endpoint_create
#'
#' @family SQL Endpoints API
#'
#' @export
db_sql_endpoint_delete <- function(id,
                                   host = db_host(), token = db_token(),
                                   perform_request = TRUE) {

  req <- db_request(
    endpoint = paste0("sql/endpoints/", id),
    method = "DELETE",
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

#' Edit SQL Endpoint
#'
#' @inheritParams auth_params
#' @inheritParams db_sql_endpoint_create
#' @inheritParams db_sql_endpoint_delete
#'
#' @details Modify a SQL endpoint. All fields are optional. Missing fields
#' default to the current values.
#'
#' @family SQL Endpoints API
#'
#' @export
db_sql_endpoint_edit <- function(id,
                                 name = NULL,
                                 cluster_size = NULL,
                                 min_num_clusters = NULL,
                                 max_num_clusters = NULL,
                                 auto_stop_mins = NULL,
                                 tags = NULL,
                                 spot_instance_policy = NULL,
                                 enable_photon = NULL,
                                 enable_serverless_compute = NULL,
                                 channel = NULL,
                                 host = db_host(), token = db_token(),
                                 perform_request = TRUE) {

  # checks
  sizes <- c(
    "2X-Small", "X-Small", "Small",
    "Medium", "Large", "X-Large",
    "2X-Large", "3X-Large", "4X-Large"
  )

  stopifnot(
    cluster_size %in% sizes,
    spot_instance_policy %in% c("COST_OPTIMIZED", "RELIABILITY_OPTIMIZED"),
    channel %in% c("CHANNEL_NAME_CURRENT", "CHANNEL_NAME_PREVIEW")
  )

  if (!is.null(channel)) {
    channel <- list(name = channel)
  }

  body <- list(
    name = name,
    cluster_size = cluster_size,
    min_num_clusters = min_num_clusters,
    max_num_clusters = max_num_clusters,
    auto_stop_mins = auto_stop_mins,
    spot_instance_policy = spot_instance_policy,
    enable_photon = enable_photon,
    enable_serverless_compute = enable_serverless_compute,
    channel = channel
  )

  req <- db_request(
    endpoint = paste("sql/endpoints", id, "edit", sep = "/"),
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

#' Get SQL Endpoint
#'
#' @inheritParams auth_params
#' @inheritParams db_sql_endpoint_delete
#' @inheritParams db_sql_endpoint_create
#'
#' @family SQL Endpoints API
#'
#' @export
db_sql_endpoint_get <- function(id, host = db_host(), token = db_token(),
                                perform_request = TRUE) {
  req <- db_request(
    endpoint = paste0("sql/endpoints/", id),
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

#' List SQL Endpoints
#'
#' @inheritParams auth_params
#' @inheritParams db_sql_endpoint_create
#'
#' @family SQL Endpoints API
#'
#' @export
db_sql_endpoint_list <- function(host = db_host(), token = db_token(),
                                 perform_request = TRUE) {
  req <- db_request(
    endpoint = "sql/endpoints",
    method = "GET",
    version = "2.0",
    body = NULL,
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }

}

#' Start SQL Endpoint
#'
#' @inheritParams auth_params
#' @inheritParams db_sql_endpoint_delete
#' @inheritParams db_sql_endpoint_create
#'
#' @family SQL Endpoints API
#'
#' @export
db_sql_endpoint_start <- function(id, host = db_host(), token = db_token(),
                                  perform_request = TRUE) {
  req <- db_request(
    endpoint = paste("sql/endpoints", id, "start", sep = "/"),
    method = "POST",
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

#' Stop SQL Endpoint
#'
#' @inheritParams auth_params
#' @inheritParams db_sql_endpoint_delete
#' @inheritParams db_sql_endpoint_create
#'
#' @family SQL Endpoints API
#'
#' @export
db_sql_endpoint_stop <- function(id, host = db_host(), token = db_token(),
                                 perform_request = TRUE) {
  req <- db_request(
    endpoint = paste("sql/endpoints", id, "stop", sep = "/"),
    method = "POST",
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

#' Get Global SQL endpoint Config
#'
#' @inheritParams auth_params
#' @inheritParams db_sql_endpoint_create
#'
#' @family SQL Endpoints API
#'
#' @export
db_sql_global_endpoint_get <- function(host = db_host(), token = db_token(),
                                       perform_request = TRUE) {
  req <- db_request(
    endpoint = "sql/config/endpoints",
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

#' Edit Global SQL endpoint Config
#'
#' @param data_access_config Named list of key-value pairs containing properties
#' for an external Hive metastore.
#' @param sql_configuration_parameters Named List of SQL configuration
#' parameters.
#' @param instance_profile_arn Instance profile used to access storage from SQL
#' endpoints.
#' @param security_policy The policy for controlling access to datasets. Must be
#' `DATA_ACCESS_CONTROL`.
#' @inheritParams auth_params
#' @inheritParams db_sql_endpoint_create
#'
#' @details Important:
#' - All fields are required.
#' - Invoking this method restarts **all** running SQL endpoints.
#'
#' @family SQL Endpoints API

#' @export
db_sql_global_endpoint_edit <- function(data_access_config = list(),
                                        sql_configuration_parameters = list(),
                                        instance_profile_arn = NULL,
                                        security_policy = "DATA_ACCESS_CONTROL",
                                        host = db_host(), token = db_token(),
                                        perform_request = TRUE) {
  data_access_config <- purrr::imap(
    .x = data_access_config,
    .f = function(x, y) list(key = x, value = y)
  )

  sql_configuration_parameters <- purrr::imap(
    .x = sql_configuration_parameters,
    .f = function(x, y) list(key = x, value = y)
  )

  sql_configuration_parameters <- list(
    configuration_pairs = unname(sql_configuration_parameters)
  )

  body <- list(
    data_access_config = unname(data_access_config),
    sql_configuration_parameters = sql_configuration_parameters,
    instance_profile_arn = instance_profile_arn,
    security_policy = security_policy
  )

  req <- db_request(
    endpoint = "sql/config/endpoints",
    method = "PUT",
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


### Higher Functions ###########################################################

#' Get and Start Endpoint
#'
#' @param polling_interval Number of seconds to wait between status checks
#' @inheritParams auth_params
#' @inheritParams db_sql_endpoint_start
#'
#' @details Get information regarding a Databricks cluster. If the cluster is
#' inactive it will be started and wait until the cluster is active.
#'
#' @seealso [db_sql_endpoint_get()] and [db_sql_endpoint_start()].
#'
#' @family SQL Endpoints API
#' @family Endpoint Helpers
#'
#' @return `db_sql_endpoint_get()`
#' @export
get_and_start_endpoint <- function(id, polling_interval = 5,
                                   host = db_host(), token = db_token()) {

  # get cluster status
  endpoint_status <- db_sql_endpoint_get(
    id = id,
    host = host,
    token = token
  )

  # if the endpoint isn't running, start it
  if (!endpoint_status$state %in% c("RUNNING", "STARTING")) {
    db_sql_endpoint_start(
      id = id,
      host = host,
      token = token
    )
  }

  # wait for endpoint to become active
  while (endpoint_status$state != "RUNNING") {
    Sys.sleep(polling_interval)
    endpoint_status <- db_sql_endpoint_get(
      id = id,
      host = host,
      token = token
    )
  }

  endpoint_status
}
