test_that("request helpers - building requests", {
  host <- "some_url"
  token <- "some_token"
  endpoint <- "clusters/create"
  endpoint_version <- "2.0"
  method <- "POST"
  body <- list(a = 1, b = 2)

  expect_no_condition({
    req <- db_request(
      endpoint = endpoint,
      method = method,
      version = endpoint_version,
      body = body,
      host = host,
      token = token
    )
  })

  expect_s3_class(req, "httr2_request")
  expect_identical(
    req$url,
    paste("https://", host, "/api/", endpoint_version, "/", endpoint, sep = "")
  )
  expect_identical(req$method, method)
  expect_identical(req$body$data, body)
  expect_no_error(req$options$useragent)
  expect_equal(req$policies$retry_max_tries, 3)
  req_json <- db_request_json(req)
  expect_equal(unclass(req_json), "{\"a\":1,\"b\":2}")
  expect_s3_class(req_json, "json")
  expect_null(db_request_json(NULL))
})

test_that("request helpers - m2m auth flow", {
  host <- "some_url"
  endpoint <- "clusters/create"
  endpoint_version <- "2.0"
  method <- "POST"
  body <- list(a = 1, b = 2)

  withr::local_envvar(
    DATABRICKS_CLIENT_ID = "client-id",
    DATABRICKS_CLIENT_SECRET = "client-secret"
  )

  req <- db_request(
    endpoint = endpoint,
    method = method,
    version = endpoint_version,
    body = body,
    host = host,
    token = NULL
  )

  expect_identical(
    req$policies$auth_sign$params$flow,
    "oauth_flow_client_credentials"
  )
  expect_identical(
    req$policies$auth_sign$params$flow_params$scope,
    "all-apis"
  )
  expect_identical(
    req$policies$auth_sign$params$flow_params$client$id,
    "client-id"
  )
})
