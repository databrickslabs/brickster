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
#' @param profile Profile to use when fetching from environment variable
#' (e.g. `.Renviron`) or `.databricksfg` file
#'
#' @details
#' The behaviour is subject to change depending if `db_profile` and
#' `use_databrickscfg` options are set.
#' - `use_databrickscfg`: Boolean (default: `FALSE`), determines if credentials
#' are fetched from profile of `.databrickscfg` or `.Renviron`
#' - `db_profile`: String (default: `NULL`), determines profile used.
#'
#' See vignette on authentication for more details.
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
    parsed_url <- httr2::url_parse(host)

    # inject scheme if not present then re-build with https
    if (is.null(parsed_url$schema)) {
      parsed_url$scheme <- "https"
    }

    # if hostname is missing change path to host
    if (is.null(parsed_url$host)) {
      parsed_url$hostname <- parsed_url$path
      parsed_url$path <- NULL
    }

    host <- httr2::url_build(parsed_url)
    host <- httr2::url_parse(host)$hostname

  } else {
    # otherwise construct host string
    host <- paste0(prefix, id, ".cloud.databricks.com")
  }

  host
}

#' Fetch Databricks Token
#'
#' @description
#' Token must be specified as an environment variable `DATABRICKS_TOKEN`.
#' If `DATABRICKS_TOKEN` is missing will default to using OAuth U2M flow.
#'
#' Refer to [api authentication docs](https://docs.databricks.com/dev-tools/api/latest/authentication.html)
#'
#' @family Databricks Authentication Helpers
#'
#' @inherit db_host details
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

  read_env_var(key = "token", profile = profile, error = FALSE)
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
#' @inherit db_host details
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
#' a given profile. Brickster searches for the config file in the user's home directory.
#' To see where this is you can run Sys.getenv("HOME") on unix-like operating systems,
#' or, Sys.getenv("USERPROFILE") on windows.
#'
#' @param key The value to fetch from profile. One of `token`, `host`, or `wsid`
#' @param profile Character, the name of the profile to retrieve values
#'
#' @return named list of values associated with profile
#' @import cli
#' @keywords internal
read_databrickscfg <- function(key = c("token", "host", "wsid"), profile = NULL) {
  key <- match.arg(key)

  if (is.null(profile)) {
    profile <- "DEFAULT"
  }

  if (.Platform$OS.type == "windows") {
    home_dir <- Sys.getenv("USERPROFILE")
  } else {
    home_dir <- Sys.getenv("HOME")
  }

  config_path <- file.path(home_dir, ".databrickscfg")

  # read config file (ini format) and fetch values from specified profile
  vars <- ini::read.ini(config_path)[[profile]]

  # return error in case of empty profile
  if (is.null(vars)) {
    stop(cli::format_error(c(
      "Specified {.var profile} not found in {.file `{config_path}`}:",
      "x" = "Need to specify {.envvar {profile}} profile within {.file {config_path}} file."
    )))
  }

  # attempt to fetch required key & value pair from profile
  # error if key isn't found
  value <- vars[[key]]
  if (is.null(value)) {
    stop(cli::format_error(c(
      "Parameter {.var {key}} not found in {.envvar {profile}} profile of {.file {config_path}}:",
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
#' @param error Boolean, when key isn't found should error be raised
#'
#' @return named list of values associated with profile
#' @keywords internal
read_env_var <- function(key = c("token", "host", "wsid"),
                         profile = NULL, error = TRUE) {

  key <- match.arg(key)

  # fetch value based on profile
  if (is.null(profile)) {
    key_name <- paste("DATABRICKS", toupper(key), sep = "_")
  } else {
    key_name <- paste("DATABRICKS", toupper(key), toupper(profile), sep = "_")
  }

  value <- Sys.getenv(key_name)


  if (value == "") {
    if (error) {
      stop(cli::format_error(c(
        "Environment variable {.var {key_name}} not found:",
        "x" = "Need to specify {.var {key_name}} environment variable."
      )))
    } else {
      value <- NULL
    }
  }

  value
}


#' Create OAuth 2.0 Client
#' @details Creates an OAuth 2.0 Client, support for U2M flows only.
#' May later be extended for account U2M and all M2M flows.
#'
#' @inheritParams auth_params
#'
#' @return List that contains httr2_oauth_client and relevant auth url
#' @keywords internal
db_oauth_client <- function(host = db_host()) {

  ws_token_url = glue::glue("https://{host}/oidc/v1/token", host = host)
  ws_auth_url = glue::glue("https://{host}/oidc/v1/authorize", host = host)

  client <- httr2::oauth_client(
    id = "databricks-cli",
    token_url = ws_token_url,
    name = "brickster"
  )

  client_and_auth <- list(
    client = client,
    auth_url = ws_auth_url
  )

  # add option for client to be fetched via request helpers
  options(brickster_oauth_client = client_and_auth)

  client_and_auth

}



