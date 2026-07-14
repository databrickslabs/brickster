local_clear_auth_env <- function() {
  withr::local_envvar(
    c(
      DATABRICKS_CONFIG_FILE = NA_character_,
      DATABRICKS_CONFIG_PROFILE = NA_character_,
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
}

local_error_response <- function(
  body,
  content_type = "application/json",
  status = 400
) {
  httr2::response(
    status_code = status,
    headers = list("content-type" = content_type),
    body = charToRaw(body)
  )
}

test_that("request helpers - building requests", {
  local_clear_auth_env()

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
  expect_true(req$policies$retry_on_failure)
  req_json <- db_request_json(req)
  expect_equal(unclass(req_json), "{\"a\":1,\"b\":2}")
  expect_s3_class(req_json, "json")
  expect_null(db_request_json(NULL))
})

test_that("request error body handles standard Databricks JSON errors", {
  resp <- local_error_response(
    paste0(
      '{"error_code":"PERMISSION_DENIED",',
      '"message":"You do not have permission to use the SQL Warehouse."}'
    ),
    status = 403
  )

  expect_identical(
    db_req_error_body(resp),
    "PERMISSION_DENIED: You do not have permission to use the SQL Warehouse."
  )
})

test_that("request error body handles non-JSON Databricks errors", {
  text_html_resp <- local_error_response(
    "Invalid Token",
    content_type = "text/html; charset=utf-8"
  )
  string_resp <- local_error_response(
    "DEADLINE_EXCEEDED: Deadline exceeded when awaiting statement ID",
    content_type = "text/plain"
  )
  empty_resp <- local_error_response(
    "",
    content_type = "text/html; charset=utf-8",
    status = 504
  )

  expect_identical(db_req_error_body(text_html_resp), "Invalid Token")
  expect_identical(
    db_req_error_body(string_resp),
    "DEADLINE_EXCEEDED: Deadline exceeded when awaiting statement ID"
  )
  expect_identical(db_req_error_body(empty_resp), "Gateway Timeout")
})

test_that("request helpers - m2m auth flow", {
  local_clear_auth_env()

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

test_that("request helpers isolate OAuth clients and tokens by workspace", {
  local_clear_auth_env()

  withr::local_envvar(
    DATABRICKS_CLIENT_ID = "client-id",
    DATABRICKS_CLIENT_SECRET = "client-secret"
  )

  req_a <- db_request(
    endpoint = "clusters/list",
    method = "GET",
    version = "2.0",
    host = "workspace-a.cloud.databricks.com",
    token = NULL
  )
  req_b <- db_request(
    endpoint = "clusters/list",
    method = "GET",
    version = "2.0",
    host = "workspace-b.cloud.databricks.com",
    token = NULL
  )

  client_a <- req_a$policies$auth_sign$params$flow_params$client
  client_b <- req_b$policies$auth_sign$params$flow_params$client
  expect_identical(
    client_a$token_url,
    "https://workspace-a.cloud.databricks.com/oidc/v1/token"
  )
  expect_identical(
    client_b$token_url,
    "https://workspace-b.cloud.databricks.com/oidc/v1/token"
  )
  expect_false(identical(client_a$name, client_b$name))

  cache_a <- req_a$policies$auth_sign$cache
  cache_b <- req_b$policies$auth_sign$cache
  cache_a$clear()
  cache_b$clear()
  withr::defer(cache_a$clear())
  withr::defer(cache_b$clear())

  cache_a$set(httr2::oauth_token(
    access_token = "workspace-a-token",
    expires_in = 3600
  ))

  expect_null(cache_b$get())
})

test_that("request helpers - azure m2m auth flow", {
  local_clear_auth_env()

  host <- "some_url"
  endpoint <- "clusters/create"
  endpoint_version <- "2.0"
  method <- "POST"
  body <- list(a = 1, b = 2)

  withr::local_envvar(
    ARM_CLIENT_ID = "azure-client-id",
    ARM_CLIENT_SECRET = "azure-client-secret",
    ARM_TENANT_ID = "azure-tenant-id"
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
    "2ff814a6-3304-4ab8-85cb-cd0e6f879c1d/.default"
  )
  expect_identical(
    req$policies$auth_sign$params$flow_params$token_params,
    list()
  )
  expect_identical(
    req$policies$auth_sign$params$flow_params$client$token_url,
    "https://login.microsoftonline.com/azure-tenant-id/oauth2/v2.0/token"
  )
})
