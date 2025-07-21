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
  if (packageVersion("httr2") >= "1.2.0") {
    headers <- httr2::req_get_headers(req, "reveal")
  } else {
    headers <- req$headers
  }
  expect_equal(headers$Authorization, paste("Bearer", token))

  req_json <- db_request_json(req)
  expect_equal(unclass(req_json), "{\"a\":1,\"b\":2}")
  expect_s3_class(req_json, "json")
  expect_null(db_request_json(NULL))
})
