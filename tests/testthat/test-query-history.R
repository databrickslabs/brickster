test_that("Query History API - don't perform", {
  withr::local_envvar(c(
    "DATABRICKS_HOST" = "http://mock_host",
    "DATABRICKS_TOKEN" = "mock_token"
  ))

  resp_history3 <- db_sql_query_history(
    user_ids = c(1, 2, 3),
    endpoint_ids = c("X", "Y", "Z"),
    max_results = 1,
    include_metrics = TRUE,
    perform_request = FALSE
  )
  expect_s3_class(resp_history3, "httr2_request")
})

skip_on_cran()
skip_unless_credentials_set()
skip_unless_authenticated()
skip_unless_aws_workspace()

test_that("Query History API", {
  expect_no_error(
    resp_history <- db_sql_query_history(
      max_results = 1
    )
  )

  expect_no_error(
    resp_history2 <- db_sql_query_history(
      statuses = c("FINISHED"),
      max_results = 1,
      include_metrics = FALSE,
      end_time_ms = as.integer(Sys.time()) * 1000
    )
  )
})
