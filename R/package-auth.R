# internal package functions for authentication

#' Generate/Fetch Databricks Host
#'
#' @description
#' If both `id` and `prefix` are `NULL` then the function will check for
#' the `DATABRICKS_HOST` environment variable.
#' `.databrickscfg` will be searched if `db_profile` and `use_databrickscfg` are set or if
#' Posit Workbench managed OAuth credentials are detected.
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
#' `.databrickscfg` will automatically be used when Posit Workbench managed OAuth credentials are detected.
#'
#' See vignette on authentication for more details.
#'
#' @family Databricks Authentication Helpers
#'
#' @return workspace URL
#' @export
db_host <- function(
  id = NULL,
  prefix = NULL,
  profile = default_config_profile()
) {
  if (is.null(id) && is.null(prefix)) {
    # if `use_databricks_cfg()` returns `TRUE` then fetch the associated env.
    # env is specified via `db_env` option, if missing use default.
    # this behaviour can only be changed via setting of config
    if (use_databricks_cfg()) {
      host <- read_databrickscfg(key = "host", profile = profile)
    } else {
      host <- read_env_var(key = "host", profile = profile)
    }
    parsed_url <- httr2::url_parse(host)

    # inject scheme if not present then re-build with https
    if (is.null(parsed_url$scheme)) {
      parsed_url$scheme <- "https"
    }

    # if hostname is missing change path to host
    if (is.null(parsed_url$hostname)) {
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
#' The function will check for a token in the `DATABRICKS_HOST` environment variable.
#' `.databrickscfg` will be searched if `db_profile` and `use_databrickscfg` are set or
#' if Posit Workbench managed OAuth credentials are detected.
#' If none of the above are found then `db_token()` returns `NULL` when reading
#' environment variables and errors when using `.databrickscfg`.
#'
#' Refer to [api authentication docs](https://docs.databricks.com/aws/en/dev-tools/auth)
#'
#' @family Databricks Authentication Helpers
#'
#' @inherit db_host details
#' @inheritParams db_host
#' @return databricks token
#' @export
db_token <- function(profile = default_config_profile()) {
  # if `use_databricks_cfg()` returns `TRUE` then fetch the associated env.
  # env is specified via `db_env` option, if missing use default.
  # this behaviour can only be changed via setting of config
  if (use_databricks_cfg()) {
    token <- read_databrickscfg(key = "token", profile = profile, error = FALSE)
    return(token)
  }

  read_env_var(key = "token", profile = profile, error = FALSE)
}

#' Fetch Databricks Workspace ID
#'
#' @description
#' Workspace ID, optionally specified to make connections pane more powerful.
#' Specified as an environment variable `DATABRICKS_WSID`.
#' `.databrickscfg` will be searched if `db_profile` and `use_databrickscfg` are set or
#' if Posit Workbench managed OAuth credentials are detected.
#'
#' Refer to [api authentication docs](https://docs.databricks.com/aws/en/dev-tools/auth)
#'
#' @family Databricks Authentication Helpers
#'
#' @inherit db_host details
#' @inheritParams db_host
#' @return databricks workspace ID
#' @export
db_wsid <- function(profile = default_config_profile()) {
  if (use_databricks_cfg()) {
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
  params <- lapply(strsplit(params, " ", fixed = TRUE), `[`, 2)
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
#' a given profile. Brickster searches for the config file in the user's home directory by default.
#' To see where this is you can run Sys.getenv("HOME") on unix-like operating systems,
#' or, Sys.getenv("USERPROFILE") on windows.
#' An alternate location will be used if the environment variable `DATABRICKS_CONFIG_FILE` is set.
#'
#' @param key The value to fetch from profile. One of `token`, `host`, `wsid`,
#' `client_id`, or `client_secret`
#' @param profile Character, the name of the profile to retrieve values
#'
#' @return named list of values associated with profile
#' @keywords internal
read_databrickscfg <- function(
  key = c("token", "host", "wsid", "client_id", "client_secret"),
  profile = NULL,
  error = TRUE
) {
  key <- match.arg(key)

  if (is.null(profile)) {
    profile <- "DEFAULT"
  }

  home_dir <- fs::path_home()

  # use the .databrickscfg location specified in DATABRICKS_CONFIG_FILE
  databricks_config_file <- Sys.getenv("DATABRICKS_CONFIG_FILE")
  if (!nzchar(databricks_config_file)) {
    config_path <- fs::path(home_dir, ".databrickscfg")
  } else {
    config_path <- databricks_config_file
  }
  config_path <- fs::path_real(config_path)

  # read config file (ini format) and fetch values from specified profile
  vars <- ini::read.ini(config_path)[[profile]]

  # return error in case of empty profile
  if (is.null(vars)) {
    cli::cli_abort(c(
      "Specified {.var profile} not found in {.file `{config_path}`}:",
      "x" = "Need to specify {.envvar {profile}} profile within {.file {config_path}} file."
    ))
  }

  # attempt to fetch required key & value pair from profile
  # error if key isn't found
  value <- vars[[key]]
  if (is.null(value)) {
    if (error) {
      cli::cli_abort(c(
        "Parameter {.var {key}} not found in {.envvar {profile}} profile of {.file {config_path}}:",
        "x" = "Need to specify {.envvar {key}} in {.envvar {profile}} profile."
      ))
    } else {
      value <- NULL
    }
  }

  value
}

#' Reads Environment Variables
#' @details Fetches relevant environment variables based on profile
#'
#' @param key The value to fetch from profile. One of `token`, `host`, `wsid`,
#' `client_id`, or `client_secret`
#' @param profile Character, the name of the profile to retrieve values
#' @param error Boolean, when key isn't found should error be raised
#'
#' @return named list of values associated with profile
#' @keywords internal
read_env_var <- function(
  key = c("token", "host", "wsid", "client_id", "client_secret"),
  profile = NULL,
  error = TRUE
) {
  key <- match.arg(key)

  # fetch value based on profile
  if (is.null(profile)) {
    key_name <- paste("DATABRICKS", toupper(key), sep = "_")
  } else {
    key_name <- paste("DATABRICKS", toupper(key), toupper(profile), sep = "_")
  }

  value <- Sys.getenv(key_name)

  if (!nzchar(value)) {
    if (error) {
      cli::cli_abort(c(
        "Environment variable {.var {key_name}} not found:",
        "x" = "Need to specify {.var {key_name}} environment variable."
      ))
    } else {
      value <- NULL
    }
  }

  value
}

db_client_id <- function(profile = default_config_profile()) {
  if (use_databricks_cfg()) {
    client_id <- read_databrickscfg(
      key = "client_id",
      profile = profile,
      error = FALSE
    )
    return(client_id)
  }

  read_env_var(key = "client_id", profile = profile, error = FALSE)
}

db_client_secret <- function(profile = default_config_profile()) {
  if (use_databricks_cfg()) {
    client_secret <- read_databrickscfg(
      key = "client_secret",
      profile = profile,
      error = FALSE
    )
    return(client_secret)
  }

  read_env_var(
    key = "client_secret",
    profile = profile,
    error = FALSE
  )
}

#' Create OAuth 2.0 Client
#' @details Creates an OAuth 2.0 Client for U2M or M2M flows.
#'
#' @inheritParams auth_params
#'
#' @param client_id OAuth M2M client id. When set with `client_secret` the
#' client will use M2M auth.
#' @param client_secret OAuth M2M client secret.
#'
#' @return List that contains [httr::2oauth_client()], relevant `auth_url`, and `is_m2m`
#' @keywords internal
db_oauth_client <- function(
  host = db_host(),
  client_id = db_client_id(),
  client_secret = db_client_secret()
) {
  is_m2m <- !is.null(client_id) &&
    nzchar(client_id) &&
    !is.null(client_secret) &&
    nzchar(client_secret)

  ws_token_url = glue::glue("https://{host}/oidc/v1/token", host = host)
  ws_auth_url = glue::glue("https://{host}/oidc/v1/authorize", host = host)

  if (is_m2m) {
    client <- httr2::oauth_client(
      id = client_id,
      secret = client_secret,
      token_url = ws_token_url,
      name = "brickster"
    )
  } else {
    client <- httr2::oauth_client(
      id = "databricks-cli",
      token_url = ws_token_url,
      name = "brickster"
    )
  }

  client_and_auth <- list(
    client = client,
    auth_url = ws_auth_url,
    is_m2m = is_m2m
  )

  # add option for client to be fetched via request helpers
  options(brickster_oauth_client = client_and_auth)

  client_and_auth
}

#' Returns the default config profile
#' @details Returns the config profile first looking at `DATABRICKS_CONFIG_PROFILE`
#' and then the `db_profile` option.
#'
#' @return profile name
#' @keywords internal
default_config_profile <- function() {
  profile <- Sys.getenv("DATABRICKS_CONFIG_PROFILE")
  if (nzchar(profile)) {
    profile
  } else {
    getOption("db_profile")
  }
}

#' Returns whether or not to use a `.databrickscfg` file
#' @details Indicates `.databrickscfg` should be used instead of environment variables when
#' either the `use_databrickscfg` option is set or Posit Workbench managed OAuth credentials are detected.
#'
#' @return boolean
#' @keywords internal
use_databricks_cfg <- function() {
  use_databricks_cfg <- getOption("use_databrickscfg", FALSE)
  if (
    grepl("posit-workbench", Sys.getenv("DATABRICKS_CONFIG_FILE"), fixed = TRUE)
  ) {
    use_databricks_cfg <- TRUE
  }
  return(use_databricks_cfg)
}


# Extended from {odbc}
#
# Try to determine whether we can redirect the user's browser to a server on
# localhost, which isn't possible if we are running on a hosted platform.
#
# This is based on the strategy pioneered by the {gargle} package and {httr2}.
is_hosted_session <- function() {
  if (on_databricks()) {
    return(TRUE)
  }

  if (nzchar(Sys.getenv("COLAB_RELEASE_TAG"))) {
    return(TRUE)
  }

  # If RStudio Server or Posit Workbench is running locally (which is possible,
  # though unusual), it's not acting as a hosted environment.
  Sys.getenv("RSTUDIO_PROGRAM_MODE") == "server" &&
    !grepl("localhost", Sys.getenv("RSTUDIO_HTTP_REFERER"), fixed = TRUE)
}
