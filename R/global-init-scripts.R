# https://docs.databricks.com/dev-tools/api/latest/global-init-scripts.html

#' Get All Global Init Scripts (Summaries)
#'
#' Get a list of all global init scripts for this workspace.
#'
#' @inheritParams auth_params
#' @inheritParams db_sql_endpoint_create
#'
#' @family Global Init Script API
#'
#' @details
#' This returns all properties for each script but not the script contents.
#' To retrieve the contents of a script, use [db_global_init_scripts_get()]
#'
#' @export
db_global_init_scripts_list <- function(host = db_host(), token = db_token(),
                                        perform_request = TRUE) {
  req <- db_request(
    endpoint = "global-init-scripts",
    method = "GET",
    version = "2.0",
    host = host,
    token = token
  )


  if (perform_request) {
    res <- db_perform_request(req)
    dplyr::bind_rows(unname(res))
  } else {
    req
  }

}

#' Get a Global Init Script
#'
#' Get all the details of a script, including its Base64-encoded contents.
#'
#' @param script_id String, the ID of the global init script.
#' @inheritParams auth_params
#' @inheritParams db_sql_endpoint_create
#'
#' @details Base64-encoded contents are converted to character automatically.
#'
#' @family Global Init Script API
#'
#' @export
db_global_init_scripts_get <- function(script_id,
                                       host = db_host(), token = db_token(),
                                       perform_request = TRUE) {
  req <- db_request(
    endpoint = paste0("global-init-scripts/", script_id),
    method = "GET",
    version = "2.0",
    host = host,
    token = token
  )


  if (perform_request) {
    res <- db_perform_request(req)
    # decode the script component
    res$script <- base::rawToChar(base64enc::base64decode(res$script))
    res
  } else {
    req
  }

}

#' Create a Global Init Script
#'
#' @param name The name of the script
#' @param script String, content of script.
#' @param position Position of the global init script, must be >=1.
#'   When not specified the script goes to last position.
#'   When position already exists it will take position and displace existing.
#' @param enabled Boolean (default: false). Specifies whether the script is enabled.
#'   The script runs only if enabled.
#' @inheritParams auth_params
#' @inheritParams db_sql_endpoint_create
#'
#' @details
#' The [Global Init Scripts API](https://docs.databricks.com/dev-tools/api/latest/global-init-scripts.html)
#' enables Databricks administrators to configure global initialization scripts
#' for their workspace.
#'
#' These scripts run on every node in every cluster in the workspace.
#' Existing clusters must be restarted to pick up any changes made to global
#' init scripts.
#'
#' Global init scripts are run in order. If the init script returns with a bad
#' exit code, the Apache Spark container fails to launch and init scripts with
#' later position are skipped. If enough containers fail, the entire cluster
#' fails with a `GLOBAL_INIT_SCRIPT_FAILURE` error code.
#'
#' @family Global Init Script API
#'
#' @export
db_global_init_scripts_create <- function(name, script, position = NULL,
                                          enabled = FALSE,
                                          host = db_host(), token = db_token(),
                                          perform_request = TRUE) {
  stopifnot(
    "`position` must be >= 1" = position >= 1,
    "`enabled` must be boolean" = is.logical(enabled)
  )

  body <- list(
    name = name,
    script = base64enc::base64encode(base::charToRaw(script)),
    position = position,
    enabled = ifelse(enabled, "true", "false") # doesn't like bool :(
  )

  req <- db_request(
    endpoint = "global-init-scripts",
    method = "POST",
    version = "2.0",
    body = body,
    host = host,
    token = token
  )

  if (perform_request) {
    res <- db_perform_request(req)
    res$script_id
  } else {
    req
  }

}

#' Update a Global Init Script
#'
#' @inheritParams db_global_init_scripts_create
#' @inheritParams db_global_init_scripts_get
#' @inheritParams auth_params
#' @inheritParams db_sql_endpoint_create
#'
#' @details
#' All fields are optional.
#' Unspecified fields retain their current value.
#'
#' @family Global Init Script API
#'
#' @export
db_global_init_scripts_update <- function(script_id, name = NULL,
                                          script = NULL, position = NULL,
                                          enabled = NULL,
                                          host = db_host(), token = db_token(),
                                          perform_request = TRUE) {
  if (!is.null(position)) {
    stopifnot("`position` must be >= 1" = position >= 1)
  }

  if (!is.null(script)) {
    script <- base64enc::base64encode(base::charToRaw(script))
  }

  if (!is.null(enabled)) {
    stopifnot("`enabled` must be boolean" = is.logical(enabled))
    enabled <- ifelse(enabled, "true", "false")
  }

  body <- list(
    name = name,
    script = script,
    position = position,
    enabled = enabled
  )

  req <- db_request(
    endpoint = paste0("global-init-scripts/", script_id),
    method = "PATCH",
    version = "2.0",
    body = body,
    host = host,
    token = token
  )

  if (perform_request) {
    res <- db_perform_request(req)
    res$script_id
  } else {
    req
  }

}

#' Delete a Global Init Script
#'
#' @inheritParams auth_params
#' @inheritParams db_global_init_scripts_get
#' @inheritParams db_sql_endpoint_create
#'
#' @family Global Init Script API
#'
#' @export
db_global_init_scripts_delete <- function(script_id,
                                          host = db_host(), token = db_token(),
                                          perform_request = TRUE) {
  req <- db_request(
    endpoint = paste0("global-init-scripts/", script_id),
    method = "DELETE",
    version = "2.0",
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)
    NULL
  } else {
    req
  }

}
