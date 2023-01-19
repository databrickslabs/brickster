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
#' @param prefix Workspace prefix
#' @param profile Profile to use when fetching from environment variable or
#' `.databricksfg` file
#'
#' @family Databricks Authentication Helpers
#'
#' @return workspace URL
#' @export
db_host <- function(id = NULL, prefix = NULL, profile = getOption("db_profile", NULL)) {

  # if option `use_databrickscfg` is `TRUE` then fetch the associated env.
  # env is specified via `db_env` option, if missing use default.
  # this behaviour can only be changed via setting of config
  if (getOption("use_databrickscfg", FALSE)) {
    host <- read_databrickscfg(key = "host", profile = profile)
    return(host)
  }

  if (is.null(id) && is.null(prefix)) {
    host <- read_env_var(key = "host", profile = profile)
  } else {
    # otherwise construct host string
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
#' @inheritParams db_host
#' @return databricks token
#' @import cli
#' @export
db_token <- function(profile = getOption("db_profile")) {

  # if option `use_databrickscfg` is `TRUE` then fetch the associated env.
  # env is specified via `db_env` option, if missing use default.
  # this behaviour can only be changed via setting of config
  if (getOption("use_databrickscfg", FALSE)) {
    token <- read_databrickscfg(key = "token", profile = profile)
    return(token)
  }

  read_env_var(key = "token", profile = profile)
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
#' @inheritParams db_host
#' @return databricks workspace ID
#' @import cli
#' @export
db_wsid <- function(profile = getOption("db_profile")) {
  if (getOption("use_databrickscfg", FALSE)) {
    wsid <- read_databrickscfg(key = "wsid", profile = profile)
    return(wsid)
  }

  read_env_var(key = "wsid", profile = profile)
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


#' Reads Databricks CLI Config
#' @details Reads `.databrickscfg` file and retrieves the values associated to
#' a given profile. Brickster searches for this file in the home directory.
#'
#' @param key The value to fetch from profile. One of `token`, `host`, or `wsid`
#' @param profile Character, the name of the profile to retrieve values
#'
#' @return named list of values associated with profile
#' @import cli
read_databrickscfg <- function(key = c("token", "host", "wsid"), profile = NULL) {
  key <- match.arg(key)

  if (is.null(profile)) {
    profile <- "DEFAULT"
  }

  home_dir <- Sys.getenv("HOME")
  config_path <- file.path(home_dir, ".databrickscfg")

  # read config file (ini format) and fetch values from specified profile
  vars <- ini::read.ini(config_path)[[profile]]

  # return error in case of empty profile
  if (is.null(vars)) {
    stop(cli::format_error(c(
      "Specified {.var profile} not found in {.file `~/.databrickscfg`}:",
      "x" = "Need to specify {.envvar {profile}} profile within {.file {config_path}} file."
    )))
  }

  # attempt to fetch required key & value pair from profile
  # error if key isn't found
  value <- vars[[key]]
  if (is.null(vars)) {
    stop(cli::format_error(c(
      "Parameter {.var key} not found in profile of {.file {config_path}}:",
      "x" = "Need to specify {.envvar {key}} in {.envvar {profile}} profile."
    )))
  }

  value
}

#' Reads Environment Variables
#' @details Fetches relevant environment variables based on profile
#'
#' @param key The value to fetch from profile. One of `token`, `host`, or `wsid`
#' @param profile Character, the name of the profile to retrieve values
#'
#' @return named list of values associated with profile
read_env_var <- function(key = c("token", "host", "wsid"), profile = NULL) {
  key <- match.arg(key)

  # fetch value based on profile
  if (is.null(profile)) {
    key_name <- paste("DATABRICKS", toupper(key), sep = "_")
  } else {
    key_name <- paste("DATABRICKS", toupper(key), toupper(profile), sep = "_")
  }

  value <- Sys.getenv(key_name)

  if (value == "") {
    stop(cli::format_error(c(
      "{.var {key}} not found:",
      "x" = "Need to specify {.var {key}} environment variable."
    )))
  }

  value
}
