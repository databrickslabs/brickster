#' Get Current User Info
#'
#' @inheritParams auth_params
#' @inheritParams db_dbfs_create
#'
#' @return list of user metadata
#' @export
db_current_user <- function(host = db_host(), token = db_token(),
                            perform_request = TRUE) {
  req <- db_request(
    endpoint = "preview/scim/v2/Me",
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

#' Detect Current Workspace ID
#'
#' @inheritParams auth_params
#' @inheritParams db_dbfs_create
#'
#' @return String
#' @export
db_current_workspace_id <- function(host = db_host(), token = db_token(),
                                    perform_request = TRUE) {

  req <- db_request(
    endpoint = "preview/scim/v2/Me",
    method = "GET",
    version = "2.0",
    host = host,
    token = token
  )

  if (perform_request) {
    resp <- req |>
      httr2::req_error(body = db_req_error_body) |>
      httr2::req_perform() |>
      httr2::resp_headers()

    # workspace id can be extracted from response headers
    resp[["x-databricks-org-id"]]

  } else {
    req
  }
}

#' Detect Current Workspaces Cloud
#'
#' @inheritParams auth_params
#' @inheritParams db_dbfs_create
#'
#' @return String
#' @export
db_current_cloud <- function(host = db_host(), token = db_token(),
                                    perform_request = TRUE) {

  nodes <- db_cluster_list_node_types(host = host, token = token)
  family <- nodes[[1]][[1]]$node_instance_type$instance_family
  family_prefix <- strsplit(family, " ")[[1]][1]

  if (family_prefix == "EC2") {
    return("aws")
  } else if (family_prefix == "GCP") {
    return("gcp")
  } else {
    return("azure")
  }

}





