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
    "https://dev-mock.cloud.databricks.com"
  )
  expect_identical(
    db_host(id = "mock"),
    "https://mock.cloud.databricks.com"
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
