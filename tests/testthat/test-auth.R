test_that("auth functions - baseline behaviour", {

  host <- "some_url"
  token <- "dapi123"
  wsid <- "123"

  # set values temporarily
  withr::local_envvar(
    DATABRICKS_WSID = wsid,
    DATABRICKS_HOST = host,
    DATABRICKS_TOKEN = token
  )

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
  withr::with_envvar(
    new = c(DATABRICKS_HOST = ""),
    expect_error(db_host())
  )

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

  # set values temporarily
  withr::local_envvar(
    DATABRICKS_WSID = wsid,
    DATABRICKS_HOST = host,
    DATABRICKS_TOKEN = token,
    DATABRICKS_HOST_PROD = host_prod,
    DATABRICKS_TOKEN_PROD = token_prod,
    DATABRICKS_WSID_PROD = wsid_prod
  )

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

  withr::local_options(use_databrickscfg = TRUE)
  withr::local_envvar(DATABRICKS_CONFIG_FILE = "databricks.cfg")
  withr::local_file("databricks.cfg", {
    writeLines(
      c(
        '[DEFAULT]',
        'host = some-host',
        'token = some-token',
        'wsid = 123456'
      ),
      "databricks.cfg"
    )
  })

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
    withr::with_envvar(
      new = c(DATABRICKS_HOST = input),
      {
        expect_no_error(db_host())
        expect_identical(db_host(), output)
      }
    )
  })

})


test_that("auth functions - workbench managed credentials detection", {
  # Emulate the databricks.cfg file written by Workbench.
  db_home <- tempfile("posit-workbench")
  dir.create(db_home)
  writeLines(
    c(
      '[workbench]',
      'host = some-host',
      'token = some-token'
    ),
    file.path(db_home, "databricks.cfg")
  )
  # Two env variables need to be set on Workbench for detection to succeed
  # DATABRICKS_CONFIG_FILE with the path to the databricks.cfg file
  # DATABRICKS_CONFIG_PROFILE = "workbench" to set the profile correctly
  withr::local_envvar(
    DATABRICKS_CONFIG_FILE = file.path(db_home, "databricks.cfg"),
    DATABRICKS_CONFIG_PROFILE = "workbench"
  )

  token_w <- db_token()
  host_w <- db_host()

  expect_true(is.character(token_w))
  expect_true(is.character(host_w))

  expect_identical("some-host", host_w)
  expect_identical("some-token", token_w)

  Sys.unsetenv("DATABRICKS_CONFIG_PROFILE")
  expect_error(db_host()())
  expect_error(db_token()())

  withr::local_envvar(
    DATABRICKS_CONFIG_FILE = file.path(db_home, "databricks.cfg"),
    DATABRICKS_CONFIG_PROFILE = "workbench"
  )

  Sys.unsetenv("DATABRICKS_CONFIG_FILE")
  expect_error(db_host()())
  expect_error(db_token()())

})


test_that("auth functions - workbench managed credentials override env var", {

  withr::local_file("posit-workbench.cfg", {
    writeLines(
      c(
        '[workbench]',
        'host = some-host',
        'token = some-token'
      ),
      "posit-workbench.cfg"
    )
  })


  # # Emulate the databricks.cfg file written by Workbench.
  # db_home <- tempfile("posit-workbench")
  # dir.create(db_home)
  #
  # Two env variables need to be set on Workbench for detection to succeed
  # DATABRICKS_CONFIG_FILE with the path to the databricks.cfg file
  # DATABRICKS_CONFIG_PROFILE = "workbench" to set the profile correctly
  # Add different `DATABRICKS_HOST` and `DATABRICKS_TOKEN` env variables to ensure
  # the credentials from Workbench still get used
  withr::local_envvar(
    DATABRICKS_CONFIG_FILE = "posit-workbench.cfg",
    DATABRICKS_CONFIG_PROFILE = "workbench",
    DATABRICKS_HOST = "env-based-host",
    DATABRICKS_TOKEN = "env-based-token"
  )

  token_w <- db_token()
  host_w <- db_host()

  expect_true(is.character(token_w))
  expect_true(is.character(host_w))

  expect_identical("some-host", host_w)
  expect_identical("some-token", token_w)

})

