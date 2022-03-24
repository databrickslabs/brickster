# https://docs.databricks.com/dev-tools/api/latest/libraries.html

#' Get Status of All Libraries on All Clusters
#'
#' @details
#' A status will be available for all libraries installed on clusters via the
#' API or the libraries UI as well as libraries set to be installed on all
#' clusters via the libraries UI.
#'
#' If a library has been set to be installed on all clusters,
#' `is_library_for_all_clusters` will be true, even if the library was
#' also installed on this specific cluster.
#'
#' @inheritParams auth_params
#' @inheritParams db_sql_endpoint_create
#'
#' @family Libraries API
#'
#' @export
db_libs_all_cluster_statuses <- function(host = db_host(), token = db_token(),
                                         perform_request = TRUE) {
  req <- db_request(
    endpoint = "libraries/all-cluster-statuses",
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

#' Get Status of Libraries on Cluster
#'
#' @inherit db_libs_all_cluster_statuses description
#'
#' @param cluster_id Unique identifier of a Databricks cluster.
#' @inheritParams auth_params
#' @inheritParams db_sql_endpoint_create
#'
#' @family Libraries API
#' @seealso [wait_for_lib_installs()]
#'
#' @export
db_libs_cluster_status <- function(cluster_id,
                                   host = db_host(), token = db_token(),
                                   perform_request = TRUE) {
  body <- list(
    cluster_id = cluster_id
  )

  req <- db_request(
    endpoint = "libraries/cluster-status",
    method = "GET",
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

#' Install Library on Cluster
#'
#' @details
#'  Installation is asynchronous - it completes in the background after the request.
#'
#'  This call will fail if the cluster is terminated. Installing a wheel library
#'  on a cluster is like running the pip command against the wheel file directly
#'  on driver and executors.
#'
#'  Installing a wheel library on a cluster is like running the pip command
#'  against the wheel file directly on driver and executors. All the
#'  dependencies specified in the library setup.py file are installed and this
#'  requires the library name to satisfy the wheel file name convention.
#'
#'  The installation on the executors happens only when a new task is launched.
#'  With Databricks Runtime 7.1 and below, the installation order of libraries
#'  is nondeterministic. For wheel libraries, you can ensure a deterministic
#'  installation order by creating a zip file with suffix .wheelhouse.zip that
#'  includes all the wheel files.
#'
#' @param libraries An object created by [libraries()] and the appropriate
#' `lib_*()` functions.
#' @inheritParams db_libs_cluster_status
#' @inheritParams auth_params
#' @inheritParams db_sql_endpoint_create
#' @seealso [lib_egg()], [lib_cran()], [lib_jar()], [lib_maven()], [lib_pypi()],
#' [lib_whl()]
#'
#' @family Libraries API
#'
#' @export
db_libs_install <- function(cluster_id, libraries,
                            host = db_host(), token = db_token(),
                            perform_request = TRUE) {

  stopifnot(is.libraries(libraries))

  body <- list(
    cluster_id = cluster_id,
    libraries = lapply(libraries, unclass)
  )

  req <- db_request(
    endpoint = "libraries/install",
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

#' Uninstall Library on Cluster
#'
#' @details
#' The libraries aren’t uninstalled until the cluster is restarted.
#'
#' Uninstalling libraries that are not installed on the cluster has no impact
#' but is not an error.
#'
#' @inheritParams db_libs_install
#' @inheritParams auth_params
#' @inheritParams db_sql_endpoint_create
#'
#' @family Libraries API
#'
#' @export
db_libs_uninstall <- function(cluster_id, libraries,
                              host = db_host(), token = db_token(),
                              perform_request = TRUE) {
  stopifnot(is.libraries(libraries))

  body <- list(
    cluster_id = cluster_id,
    libraries = lapply(libraries, unclass)
  )

  req <- db_request(
    endpoint = "libraries/uninstall",
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

#' Wait for Libraries to Install on Databricks Cluster
#'
#' @details
#' Library installs on Databricks clusters are asynchronous, this function
#' allows you to repeatedly check installation status of each library.
#'
#' Can be used to block any scripts until required dependencies are installed.
#'
#' @inheritParams db_libs_install
#' @inheritParams auth_params
#' @inheritParams get_and_start_cluster
#' @param allow_failures If `FALSE` (default) will error if any libraries status
#' is `FAILED`. When `TRUE` any `FAILED` installs will be presented as a
#' warning.
#'
#' @seealso [db_libs_cluster_status()]
#'
#' @export
wait_for_lib_installs <- function(cluster_id, polling_interval = 5,
                                  allow_failures = FALSE,
                                  host = db_host(), token = db_token()) {

  # will enter into while loop, saves code outside while
  lib_statuses <- "INSTALLING"

  # get library statuses until all installed
  while (any(lib_statuses == "INSTALLING")) {

    # query for status of libs
    lib_query <- db_libs_cluster_status(cluster_id = cluster_id, host = host, token = token)
    lib_statuses <- purrr::map_chr(lib_query$library_statuses, "status")

    # if failures are not allowed and failur occurs then raise an error
    if (!allow_failures && "FAILED" %in% lib_statuses) {
      stop("Libraries failed to install")
    }

    if (!any(lib_statuses == "INSTALLING")) break

    Sys.sleep(polling_interval)

  }

  if (allow_failures && "FAILED" %in% lib_statuses) {
    num_failures <- sum(lib_statuses == "FAILED")
    warning("Failed installs: ", num_failures)
  }

  NULL

}




