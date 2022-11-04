# https://docs.databricks.com/dev-tools/api/1.2/index.html#id36

#' Create an Execution Context
#'
#' @param cluster_id The ID of the cluster to create the context for.
#' @param language The language for the context. One of `python`, `sql`, `scala`,
#' `r`.
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @family Execution Context API
#'
#' @export
db_context_create <- function(cluster_id,
                              language = c("python", "sql", "scala", "r"),
                              host = db_host(), token = db_token(),
                              perform_request = TRUE) {

  language <- match.arg(language, several.ok = FALSE)

  body <- list(
    clusterId = cluster_id,
    language = language
  )

  req <- db_request(
    endpoint = "contexts/create",
    method = "POST",
    version = "1.2",
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

#' Delete an Execution Context
#'
#' @param context_id The ID of the execution context.
#' @inheritParams auth_params
#' @inheritParams db_context_create
#' @inheritParams db_sql_warehouse_create
#'
#' @family Execution Context API
#'
#' @export
db_context_destroy <- function(cluster_id,
                               context_id,
                               host = db_host(), token = db_token(),
                               perform_request = TRUE) {

  body <- list(
    clusterId = cluster_id,
    contextId = context_id
  )

  req <- db_request(
    endpoint = "contexts/destroy",
    method = "POST",
    version = "1.2",
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

#' Get Information About an Execution Context
#'
#' @inheritParams auth_params
#' @inheritParams db_context_destroy
#' @inheritParams db_sql_warehouse_create
#'
#' @family Execution Context API
#'
#' @export
db_context_status <- function(cluster_id,
                              context_id,
                              host = db_host(), token = db_token(),
                              perform_request = TRUE) {
  req <- db_request(
    endpoint = "contexts/status",
    method = "GET",
    version = "1.2",
    host = host,
    token = token
  )

  req <- req %>%
    httr2::req_url_query(
      clusterId = cluster_id,
      contextId = context_id
    )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }

}

#' Run a Command
#'
#' @param command The command string to run.
#' @param command_file The path to a file containing the command to run.
#' @param options Named list of values used downstream. For example, a
#' 'displayRowLimit' override (used in testing).
#' @inheritParams auth_params
#' @inheritParams db_context_destroy
#' @inheritParams db_context_create
#' @inheritParams db_sql_warehouse_create
#'
#' @family Execution Context API
#'
#' @export
db_context_command_run <- function(cluster_id,
                                   context_id,
                                   language = c("python", "sql", "scala", "r"),
                                   command = NULL,
                                   command_file = NULL,
                                   options = list(),
                                   host = db_host(), token = db_token(),
                                   perform_request = TRUE) {

  language <- match.arg(language, several.ok = FALSE)

  # only can have one of `command` or `command_file`
  if (!is.null(command) && !is.null(command_file)) {
    stop("Must `command` OR `command_file` not both.")
  }

  if (!is.null(command_file)) {
    command <- curl::form_file(command_file)
  }

  req <- db_request(
    endpoint = "commands/execute",
    method = "POST",
    version = "1.2",
    body = NULL,
    host = host,
    token = token
  )

  req <- httr2::req_body_multipart(
    req,
    clusterId = cluster_id,
    contextId = context_id,
    language = language,
    command = command,
    options = options
  )

    if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }

}

#' Get Information About a Command
#'
#' @param command_id The ID of the command to get information about.
#' @inheritParams auth_params
#' @inheritParams db_context_status
#' @inheritParams db_sql_warehouse_create
#'
#' @family Execution Context API
#'
#' @export
db_context_command_status <- function(cluster_id,
                                      context_id,
                                      command_id,
                                      host = db_host(), token = db_token(),
                                      perform_request = TRUE) {

  req <- db_request(
    endpoint = "commands/status",
    method = "GET",
    version = "1.2",
    host = host,
    token = token
  )

  req <- req %>%
    httr2::req_url_query(
      clusterId = cluster_id,
      contextId = context_id,
      commandId = command_id
    )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }

}

#' Cancel a Command
#'
#' @inheritParams auth_params
#' @inheritParams db_context_command_status
#' @inheritParams db_sql_warehouse_create
#'
#' @family Execution Context API
#'
#' @export
db_context_command_cancel <- function(cluster_id,
                                      context_id,
                                      command_id,
                                      host = db_host(), token = db_token(),
                                      perform_request = TRUE) {

  req <- db_request(
    endpoint = "commands/cancel",
    method = "POST",
    version = "1.2",
    host = host,
    token = token
  )

  req <- req %>%
    httr2::req_url_query(
      clusterId = cluster_id,
      contextId = context_id,
      commandId = command_id
    )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }

}
