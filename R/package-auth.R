# internal package functions for authentication

#' Generate/Fetch Databricks Host
#'
#' @description
#' If both `id` and `prefix` are `NULL` function will search for the
#' `DATABRICKS_HOST` environment variable.
#'
#' When defining `id` and `prefix` you do not need to specify the whole URL.
#' E.g. `https://<prefix>.<id>.cloud.databricks.com/` is the form to follow.
#'
#' @param id The workspace string
#' @param prefix workspace prefix
#'
#' @family Databricks Authentication Helpers
#'
#' @return workspace URL
#' @export
db_host <- function(id = NULL, prefix = NULL) {
  if (is.null(id) && is.null(prefix)) {
    host <- Sys.getenv("DATABRICKS_HOST")

    if (host == "") {
      stop(format_error(c(
        "`DATABRICKS_HOST` not found in `.Renviron`:",
        "x" = "Need to specify `DATABRICKS_HOST` within `.Renviron` file."
      )))
    }
  } else {
    host <- paste0("https://", prefix, id, ".cloud.databricks.com")
  }

  host
}

#' Fetch Databricks Token
#'
#' @description
#' Token must be specified as an environment variable `DATABRICKS_TOKEN`.
#'
#' Refer to [api authentication docs](https://docs.databricks.com/dev-tools/api/latest/authentication.html)
#'
#' @family Databricks Authentication Helpers
#'
#' @return databricks token
#' @import cli
#' @export
db_token <- function() {
  token <- Sys.getenv("DATABRICKS_TOKEN")

  if (token == "") {
    stop(cli::format_error(c(
      "`DATABRICKS_TOKEN` not found in `.Renviron`:",
      "x" = "Need to specify `DATABRICKS_TOKEN` within `.Renviron` file."
    )))
  }

  token
}

#' Fetch Databricks Workspace ID
#'
#' @description
#' Workspace ID, optionally specificied to make connections pane more powerful.
#' Specified as an environment variable `DATABRICKS_WSID`.
#'
#' Refer to [api authentication docs](https://docs.databricks.com/dev-tools/api/latest/authentication.html)
#'
#' @family Databricks Authentication Helpers
#'
#' @return databricks workspace ID
#' @import cli
#' @export
db_wsid <- function() {
  token <- Sys.getenv("DATABRICKS_WSID")

  if (token == "") {
    stop(cli::format_error(c(
      "`DATABRICKS_WSID` not found in `.Renviron`:",
      "x" = "Need to specify `DATABRICKS_WSID` within `.Renviron` file."
    )))
  }

  token
}


#' Read .netrc File
#'
#' @param path path of `.netrc` file, default is `~/.netrc`.
#'
#' @family Databricks Authentication Helpers
#'
#' @return named list of `.netrc` entries
#' @export
db_read_netrc <- function(path = "~/.netrc") {
  # nocov start
  params <- readLines(path, warn = FALSE)
  params <- lapply(strsplit(params, " "), `[`, 2)
  setNames(params, c("machine", "login", "password"))
  # nocov end
}

#' @name auth_params
#' @param host Databricks workspace URL, defaults to calling [db_host()].
#' @param token Databricks workspace token, defaults to calling [db_token()].
#'
NULL

