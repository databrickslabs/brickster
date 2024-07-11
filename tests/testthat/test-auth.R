existing_host <- Sys.getenv("DATABRICKS_HOST")
existing_token <- Sys.getenv("DATABRICKS_TOKEN")
existing_wsid <- Sys.getenv("DATABRICKS_WSID")

test_that("auth functions - baseline behaviour", {

  host <- "some_url"
  token <- "dapi123"
  wsid <- "123"

  # set values
  Sys.setenv("DATABRICKS_HOST" = host)
  Sys.setenv("DATABRICKS_TOKEN" = token)
  Sys.setenv("DATABRICKS_WSID" = wsid)

  # read env var function should behave
  expect_identical(read_env_var("host"), host)
  expect_identical(read_env_var("token"), token)
  expect_identical(read_env_var("wsid"), wsid)
  expect_error(read_env_var("nope"))

  # higher level funcs should return as expected
  expect_identical(db_host(), host)
  expect_identical(db_token(), token)
  expect_identical(db_wsid(), wsid)

  # when not specified should error
  Sys.setenv("DATABRICKS_HOST" = "")
  expect_error(db_host())

  expect_identical(
    db_host(id = "mock", prefix = "dev-"),
    "dev-mock.cloud.databricks.com"
  )
  expect_identical(
    db_host(id = "mock"),
    "mock.cloud.databricks.com"
  )

  # oauth functions require host to be specified and valid
  expect_error(db_oauth_client(host = NULL))
  expect_identical(
    db_oauth_client(host = "")$auth_url,
    "https:///oidc/v1/authorize"
  )
  expect_identical(
    db_oauth_client(host = "")$client$token_url,
    "https:///oidc/v1/token"
  )
  expect_s3_class(
    db_oauth_client(host = "")$client,
    "httr2_oauth_client"
  )


})

test_that("auth functions - switching profile", {

  host <- "some_url"
  token <- "dapi123"
  wsid <- "123"

  host_prod <- "some_url_two"
  token_prod <- "dapi321"
  wsid_prod <- "321"

  # set values
  Sys.setenv("DATABRICKS_HOST" = host)
  Sys.setenv("DATABRICKS_TOKEN" = token)
  Sys.setenv("DATABRICKS_WSID" = wsid)

  Sys.setenv("DATABRICKS_HOST_PROD" = host_prod)
  Sys.setenv("DATABRICKS_TOKEN_PROD" = token_prod)
  Sys.setenv("DATABRICKS_WSID_PROD" = wsid_prod)

  # read env var function should behave
  expect_identical(read_env_var("host", NULL), host)
  expect_identical(read_env_var("token", NULL), token)
  expect_identical(read_env_var("wsid", NULL), wsid)
  expect_identical(read_env_var("host", "prod"), host_prod)
  expect_identical(read_env_var("token", "prod"), token_prod)
  expect_identical(read_env_var("wsid", "prod"), wsid_prod)

  # higher level funcs should return as expected
  expect_identical(db_host(profile = NULL), host)
  expect_identical(db_token(profile = NULL), token)
  expect_identical(db_wsid(profile = NULL), wsid)

  expect_identical(db_host(profile = "prod"), host_prod)
  expect_identical(db_token(profile = "prod"), token_prod)
  expect_identical(db_wsid(profile = "prod"), wsid_prod)

  # switching profiles via option checks
  # default
  expect_identical(db_host(), host)
  expect_identical(db_token(), token)
  expect_identical(db_wsid(), wsid)

  # prod test
  options(db_profile = "prod")
  expect_identical(db_host(), host_prod)
  expect_identical(db_token(), token_prod)
  expect_identical(db_wsid(), wsid_prod)

  # back to default
  options(db_profile = NULL)
  expect_identical(db_host(), host)
  expect_identical(db_token(), token)
  expect_identical(db_wsid(), wsid)

})

test_that("auth functions - reading .databrickscfg", {

  options(use_databrickscfg = TRUE)

  # where .databrickscfg should be:
  if (.Platform$OS.type == "windows") {
    home_dir <- Sys.getenv("USERPROFILE")
  } else {
    home_dir <- Sys.getenv("HOME")
  }
  dbcfg_path <- file.path(home_dir, ".databrickscfg")

  if (file.exists(dbcfg_path)) {
    # using read_databrickscfg directly
    token <- expect_no_condition(read_databrickscfg("token", profile = NULL))
    host <- expect_no_condition(read_databrickscfg("host", profile = NULL))
    wsid <- expect_no_condition(read_databrickscfg("wsid", profile = NULL))
    expect_true(is.character(token))
    expect_true(is.character(host))
    expect_true(is.character(wsid))
    # using read_databrickscfg directly
    token <- expect_no_condition(read_databrickscfg("token", profile = "DEFAULT"))
    host <- expect_no_condition(read_databrickscfg("host", profile = "DEFAULT"))
    wsid <- expect_no_condition(read_databrickscfg("wsid", profile = "DEFAULT"))
    expect_true(is.character(token))
    expect_true(is.character(host))
    expect_true(is.character(wsid))
    # via wrappers
    token_w <- db_token(profile = "DEFAULT")
    host_w <- db_host(profile = "DEFAULT")
    wsid_w <- db_wsid(profile = "DEFAULT")
    expect_identical(token, token_w)
    expect_identical(host, host_w)
    expect_identical(wsid, wsid_w)
    # via wrappers
    token_w <- db_token(profile = NULL)
    host_w <- db_host(profile = NULL)
    wsid_w <- db_wsid(profile = NULL)
    expect_identical(token, token_w)
    expect_identical(host, host_w)
    expect_identical(wsid, wsid_w)
  } else {
    expect_error(read_databrickscfg())
  }

  options(use_databrickscfg = FALSE)

})


test_that("auth functions - host handling", {

  expect_identical(
    db_host(id = "mock", prefix = "dev-"),
    "dev-mock.cloud.databricks.com"
  )

  expect_identical(
    db_host(id = "mock"),
    "mock.cloud.databricks.com"
  )

  expect_identical(
    db_host(id = "mock", prefix = "dev-"),
    "dev-mock.cloud.databricks.com"
  )

  # input and output pairs to check
  hostname_mapping <- list(
    "https://mock.cloud.databricks.com"  = "mock.cloud.databricks.com",
    "https://mock.cloud.databricks.com/" = "mock.cloud.databricks.com",
    "http://mock.cloud.databricks.com"   = "mock.cloud.databricks.com",
    "mock.cloud.databricks.com"          = "mock.cloud.databricks.com",
    "mock.cloud.databricks.com/"         = "mock.cloud.databricks.com",
    "mock.cloud.databricks.com//"        = "mock.cloud.databricks.com",
    "://mock.cloud.databricks.com"       = NULL,
    "//mock.cloud.databricks.com"        = "mock.cloud.databricks.com",
    "tps://mock.cloud.databricks.com"    = "mock.cloud.databricks.com"
  )

  purrr::iwalk(hostname_mapping, function(output, input) {
    Sys.setenv("DATABRICKS_HOST" = input)
    expect_no_error(db_host())
    expect_identical(db_host(), output)
  })

})

Sys.setenv("DATABRICKS_HOST" = existing_host)
Sys.setenv("DATABRICKS_TOKEN" = existing_token)
Sys.setenv("DATABRICKS_WSID" = existing_wsid)
