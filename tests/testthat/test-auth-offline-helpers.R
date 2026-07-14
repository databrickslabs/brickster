local_clear_cli_auth <- function() {
  withr::local_envvar(
    c(
      DATABRICKS_CLI_PATH = NA_character_,
      DATABRICKS_CONFIG_FILE = NA_character_,
      DATABRICKS_CONFIG_PROFILE = NA_character_,
      DATABRICKS_CLIENT_ID = NA_character_,
      DATABRICKS_CLIENT_SECRET = NA_character_,
      ARM_CLIENT_ID = NA_character_,
      ARM_CLIENT_SECRET = NA_character_,
      ARM_TENANT_ID = NA_character_
    ),
    .local_envir = parent.frame()
  )
  withr::local_options(
    use_databrickscfg = FALSE,
    db_profile = NULL,
    .local_envir = parent.frame()
  )
  rlang::env_unbind(
    db_cli_token_cache,
    rlang::env_names(db_cli_token_cache)
  )
  withr::defer(
    rlang::env_unbind(
      db_cli_token_cache,
      rlang::env_names(db_cli_token_cache)
    ),
    envir = parent.frame()
  )
}

local_cli_token_json <- function(expires_in = 3600) {
  jsonlite::toJSON(
    list(
      access_token = "cli-access-token",
      token_type = "Bearer",
      expiry = "2026-07-14T12:11:01.79814+10:00",
      expires_in = expires_in
    ),
    auto_unbox = TRUE
  )
}

local_sign_cli_request <- function(req) {
  policy <- req$policies$auth_sign
  do.call(
    policy$fun,
    c(
      list(req = req, cache = policy$cache),
      policy$params
    )
  )
}

test_that("configured auth types are normalized before provider routing", {
  local_clear_cli_auth()

  config_file <- fs::path(withr::local_tempdir(), "databricks.cfg")
  writeLines(
    c(
      "[DEFAULT]",
      "auth_type = oauth_m2m"
    ),
    config_file
  )
  withr::local_envvar(DATABRICKS_CONFIG_FILE = config_file)
  withr::local_options(use_databrickscfg = TRUE)

  expect_identical(db_auth_type(), "oauth-m2m")
})

test_that("OAuth auth resolution rejects non-OAuth providers", {
  local_clear_cli_auth()

  expect_error(
    resolve_oauth_auth_mode(
      auth_type = "databricks-cli",
      has_db_m2m = FALSE,
      has_azure_m2m = FALSE
    ),
    "cannot be used by the OAuth client"
  )
})

test_that("CLI token responses are parsed without exposing refresh credentials", {
  local_clear_cli_auth()
  state <- new.env(parent = emptyenv())
  state$command <- NULL
  state$args <- NULL

  local_mocked_bindings(
    run = function(command, args, ...) {
      state$command <- command
      state$args <- args
      list(
        status = 0L,
        stdout = local_cli_token_json(),
        stderr = ""
      )
    },
    .package = "processx"
  )

  token <- db_cli_token(
    host = "workspace.example.com",
    profile = NULL,
    cli_path = "/mock/databricks"
  )

  expect_identical(state$command, "/mock/databricks")
  expect_identical(
    state$args,
    c(
      "auth",
      "token",
      "--host",
      "https://workspace.example.com/"
    )
  )
  expect_identical(token$access_token, "cli-access-token")
  expect_identical(token$token_type, "Bearer")
  expect_s3_class(token, "httr2_token")
  expect_gt(token$expires_at, as.numeric(Sys.time()))
  expect_null(token$refresh_token)
})

test_that("CLI command failures are actionable", {
  local_clear_cli_auth()

  local_mocked_bindings(
    run = function(command, args, ...) {
      error <- simpleError("Databricks CLI failed")
      error$stderr <- "profile is not logged in"
      stop(error)
    },
    .package = "processx"
  )

  error <- tryCatch(
    db_cli_token(
      host = "workspace.example.com",
      profile = "DEV",
      cli_path = "/mock/databricks"
    ),
    error = identity
  )

  expect_s3_class(error, "error")
  expect_match(conditionMessage(error), "profile is not logged in")
})

test_that("CLI execution failures retain their cause", {
  local_clear_cli_auth()

  local_mocked_bindings(
    run = function(command, args, ...) {
      stop("process timed out")
    },
    .package = "processx"
  )

  expect_error(
    db_cli_token(
      host = "workspace.example.com",
      profile = "DEV",
      cli_path = "/mock/databricks"
    ),
    regexp = "process timed out"
  )
})

test_that("malformed CLI responses do not expose stdout", {
  local_clear_cli_auth()

  local_mocked_bindings(
    run = function(command, args, ...) {
      list(
        status = 0L,
        stdout = "malformed-must-not-leak",
        stderr = ""
      )
    },
    .package = "processx"
  )

  error <- tryCatch(
    db_cli_token(
      host = "workspace.example.com",
      profile = "DEV",
      cli_path = "/mock/databricks"
    ),
    error = identity
  )

  expect_s3_class(error, "error")
  expect_match(conditionMessage(error), "malformed")
  expect_false(grepl(
    "malformed-must-not-leak",
    conditionMessage(error),
    fixed = TRUE
  ))
})

test_that("invalid CLI expires_in metadata is rejected", {
  local_clear_cli_auth()

  local_mocked_bindings(
    run = function(command, args, ...) {
      list(
        status = 0L,
        stdout = jsonlite::toJSON(
          list(
            access_token = "cli-access-token",
            token_type = "Bearer",
            expiry = "2026-07-14T12:11:01.79814+10:00",
            expires_in = "not-a-number"
          ),
          auto_unbox = TRUE
        ),
        stderr = ""
      )
    },
    .package = "processx"
  )

  expect_error(
    db_cli_token(
      host = "workspace.example.com",
      profile = "DEV",
      cli_path = "/mock/databricks"
    ),
    "malformed"
  )
})

test_that("Databricks CLI auth is deferred and cached until expiry", {
  local_clear_cli_auth()
  state <- new.env(parent = emptyenv())
  state$calls <- 0L
  state$args <- NULL

  config_dir <- withr::local_tempdir()
  config_file <- fs::path(config_dir, "databricks.cfg")
  writeLines(
    c(
      "[WORKSPACE]",
      "host = https://workspace.example.com",
      "auth_type = databricks-cli",
      "[__settings__]",
      "auth_storage = secure",
      "default_profile = WORKSPACE"
    ),
    config_file
  )
  withr::local_envvar(DATABRICKS_CONFIG_FILE = config_file)
  withr::local_options(use_databrickscfg = TRUE)
  expect_identical(default_config_profile(), "WORKSPACE")

  local_mocked_bindings(
    run = function(command, args, ...) {
      state$calls <- state$calls + 1L
      state$args <- args
      list(
        status = 0L,
        stdout = local_cli_token_json(),
        stderr = ""
      )
    },
    .package = "processx"
  )

  req <- db_request(
    endpoint = "clusters/list",
    method = "GET",
    version = "2.0",
    host = "workspace.example.com",
    token = NULL
  )

  expect_s3_class(req, "httr2_request")
  expect_identical(state$calls, 0L)
  expect_s3_class(local_sign_cli_request(req), "httr2_request")
  expect_identical(state$calls, 1L)
  expect_identical(
    state$args,
    c(
      "auth",
      "token",
      "--profile",
      "WORKSPACE"
    )
  )

  req_two <- db_request(
    endpoint = "warehouses/list",
    method = "GET",
    version = "2.0",
    host = "workspace.example.com",
    token = NULL
  )
  expect_s3_class(local_sign_cli_request(req_two), "httr2_request")
  expect_identical(state$calls, 1L)

  req_two$policies$auth_sign$cache$set(httr2::oauth_token(
    access_token = "expired",
    expires_in = -1
  ))
  expect_s3_class(local_sign_cli_request(req_two), "httr2_request")
  expect_identical(state$calls, 2L)

  req_other <- db_request(
    endpoint = "warehouses/list",
    method = "GET",
    version = "2.0",
    host = "other-workspace.example.com",
    token = NULL
  )
  expect_s3_class(local_sign_cli_request(req_other), "httr2_request")
  expect_identical(state$calls, 3L)
})
