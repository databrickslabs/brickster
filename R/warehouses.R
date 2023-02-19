# https://docs.databricks.com/sql/api/sql-endpoints.html

#' Create Warehouse
#'
#' @param name Name of the SQL warehouse. Must be unique.
#' @param cluster_size Size of the clusters allocated to the warehouse. One of
#' `2X-Small`, `X-Small`, `Small`, `Medium`, `Large`, `X-Large`, `2X-Large`,
#' `3X-Large`, `4X-Large`.
#' @param min_num_clusters Minimum number of clusters available when a SQL
#' warehouse is running. The default is 1.
#' @param max_num_clusters Maximum number of clusters available when a SQL
#' warehouse is running. If multi-cluster load balancing is not enabled,
#' this is limited to 1.
#' @param auto_stop_mins Time in minutes until an idle SQL warehouse terminates
#' all clusters and stops. Defaults to 30. For Serverless SQL warehouses
#' (`enable_serverless_compute` = `TRUE`), set this to 10.
#' @param tags Named list that describes the warehouse. Databricks tags all
#' warehouse resources with these tags.
#' @param spot_instance_policy The spot policy to use for allocating instances
#' to clusters. This field is not used if the SQL warehouse is a Serverless SQL
#' warehouse.
#' @param enable_photon Whether queries are executed on a native vectorized
#' engine that speeds up query execution. The default is `TRUE`.
#' @param warehouse_type Either "CLASSIC" (default), or "PRO"
#' @param enable_serverless_compute Whether this SQL warehouse is a Serverless
#' warehouse. To use a Serverless SQL warehouse, you must enable Serverless SQL
#' warehouses for the workspace. If Serverless SQL warehouses are disabled for the
#' workspace, the default is `FALSE` If Serverless SQL warehouses are enabled for
#' the workspace, the default is `TRUE`.
#' @param disable_uc If `TRUE` will use Hive Metastore (HMS). If `FALSE`
#' (default), then it will be enabled for Unity Catalog (UC).
#' @param channel Whether to use the current SQL warehouse compute version or the
#' preview version. Databricks does not recommend using preview versions for
#' production workloads. The default is `CHANNEL_NAME_CURRENT.`
#' @param perform_request If `TRUE` (default) the request is performed, if
#' `FALSE` the httr2 request is returned *without* being performed.
#'
#' @inheritParams auth_params
#'
#' @family Warehouse API
#'
#' @export
db_sql_warehouse_create <- function(name,
                                   cluster_size,
                                   min_num_clusters = 1,
                                   max_num_clusters = 1,
                                   auto_stop_mins = 30,
                                   tags = list(),
                                   spot_instance_policy = c("COST_OPTIMIZED", "RELIABILITY_OPTIMIZED"),
                                   enable_photon = TRUE,
                                   warehouse_type = c("CLASSIC", "PRO"),
                                   enable_serverless_compute = NULL,
                                   disable_uc = FALSE,
                                   channel = c("CHANNEL_NAME_CURRENT", "CHANNEL_NAME_PREVIEW"),
                                   host = db_host(), token = db_token(),
                                   perform_request = TRUE) {

  # checks
  spot_instance_policy <- match.arg(spot_instance_policy, several.ok = FALSE)
  channel <- match.arg(channel, several.ok = FALSE)
  warehouse_type <- match.arg(warehouse_type, several.ok = FALSE)
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
    warehouse_type = warehouse_type,
    enable_serverless_compute = enable_serverless_compute,
    disable_uc = disable_uc,
    channel = list(name = channel)
  )

  req <- db_request(
    endpoint = "sql/warehouses",
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

#' Delete Warehouse
#'
#' @param id ID of the SQL warehouse.
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @family Warehouse API
#'
#' @export
db_sql_warehouse_delete <- function(id,
                                   host = db_host(), token = db_token(),
                                   perform_request = TRUE) {

  req <- db_request(
    endpoint = paste0("sql/warehouses/", id),
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

#' Edit Warehouse
#'
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#' @inheritParams db_sql_warehouse_delete
#'
#' @details Modify a SQL warehouse. All fields are optional. Missing fields
#' default to the current values.
#'
#' @family Warehouse API
#'
#' @export
db_sql_warehouse_edit <- function(id,
                                 name = NULL,
                                 cluster_size = NULL,
                                 min_num_clusters = NULL,
                                 max_num_clusters = NULL,
                                 auto_stop_mins = NULL,
                                 tags = NULL,
                                 spot_instance_policy = NULL,
                                 enable_photon = NULL,
                                 warehouse_type = NULL,
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
    channel %in% c("CHANNEL_NAME_CURRENT", "CHANNEL_NAME_PREVIEW"),
    warehouse_type <- match.arg(warehouse_type, several.ok = FALSE)
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
    warehouse_type = warehouse_type,
    enable_serverless_compute = enable_serverless_compute,
    channel = channel
  )

  req <- db_request(
    endpoint = paste("sql/warehouses", id, "edit", sep = "/"),
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

#' Get Warehouse
#'
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_delete
#' @inheritParams db_sql_warehouse_create
#'
#' @family Warehouse API
#'
#' @export
db_sql_warehouse_get <- function(id, host = db_host(), token = db_token(),
                                perform_request = TRUE) {
  req <- db_request(
    endpoint = paste0("sql/warehouses/", id),
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

#' List Warehouses
#'
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @family Warehouse API
#'
#' @export
db_sql_warehouse_list <- function(host = db_host(), token = db_token(),
                                 perform_request = TRUE) {
  req <- db_request(
    endpoint = "sql/warehouses",
    method = "GET",
    version = "2.0",
    body = NULL,
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)$warehouses
  } else {
    req
  }

}

#' Start Warehouse
#'
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_delete
#' @inheritParams db_sql_warehouse_create
#'
#' @family Warehouse API
#'
#' @export
db_sql_warehouse_start <- function(id, host = db_host(), token = db_token(),
                                  perform_request = TRUE) {
  req <- db_request(
    endpoint = paste("sql/warehouses", id, "start", sep = "/"),
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

#' Stop Warehouse
#'
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_delete
#' @inheritParams db_sql_warehouse_create
#'
#' @family Warehouse API
#'
#' @export
db_sql_warehouse_stop <- function(id, host = db_host(), token = db_token(),
                                 perform_request = TRUE) {
  req <- db_request(
    endpoint = paste("sql/warehouses", id, "stop", sep = "/"),
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

#' Get Global Warehouse Config
#'
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @family Warehouse API
#'
#' @export
db_sql_global_warehouse_get <- function(host = db_host(), token = db_token(),
                                       perform_request = TRUE) {
  req <- db_request(
    endpoint = "sql/config/warehouses",
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

### Higher Functions ###########################################################

#' Get and Start Warehouse
#'
#' @param polling_interval Number of seconds to wait between status checks
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_start
#'
#' @details Get information regarding a Databricks cluster. If the cluster is
#' inactive it will be started and wait until the cluster is active.
#'
#' @seealso [db_sql_warehouse_get()] and [db_sql_warehouse_start()].
#'
#' @family Warehouse API
#' @family Warehouse Helpers
#'
#' @return `db_sql_warehouse_get()`
#' @export
get_and_start_warehouse <- function(id, polling_interval = 5,
                                   host = db_host(), token = db_token()) {

  # get cluster status
  warehouse_status <- db_sql_warehouse_get(
    id = id,
    host = host,
    token = token
  )

  # if the warehouse isn't running, start it
  if (!warehouse_status$state %in% c("RUNNING", "STARTING")) {
    db_sql_warehouse_start(
      id = id,
      host = host,
      token = token
    )
  }

  # wait for warehouse to become active
  while (warehouse_status$state != "RUNNING") {
    Sys.sleep(polling_interval)
    warehouse_status <- db_sql_warehouse_get(
      id = id,
      host = host,
      token = token
    )
  }

  warehouse_status
}
