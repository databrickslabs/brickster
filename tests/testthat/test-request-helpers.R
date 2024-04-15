test_that("request helpers - building requests", {

  host <- "https://some_url"
  token <-  "some_token"
  endpoint <- "clusters/create"
  endpoint_version <- "2.0"
  method <- "POST"
  body <- list(a = 1, b = 2)

  expect_no_condition({
    req <- brickster:::db_request(
      endpoint = endpoint,
      method = method,
      version = endpoint_version,
      body = body,
      host = paste0(host, "/"),
      token = token
    )
  })

  expect_s3_class(req, "httr2_request")
  expect_identical(
    req$url,
    paste(host, "api", endpoint_version, endpoint, sep = "/")
  )
  expect_identical(req$method, method)
  expect_identical(req$body$data, body)
  expect_equal(req$options$useragent, "brickster/1.0")
  expect_equal(req$policies$retry_max_tries, 3)
  expect_equal(req$headers$Authorization, paste("Bearer", token))


  req_json <- db_request_json(req)
  expect_equal(unclass(req_json), "{\"a\":1,\"b\":2}")
  expect_s3_class(req_json, "json")
  expect_null(db_request_json(NULL))

})
