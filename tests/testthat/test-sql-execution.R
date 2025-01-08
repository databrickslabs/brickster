test_that("SQL Execution API - don't perform", {

  withr::local_envvar(c(
    "DATABRICKS_HOST" = "http://mock_host",
    "DATABRICKS_TOKEN" = "mock_token"
  ))

  resp_query <- db_sql_exec_query(
    statement = "select 1",
    warehouse_id = "some_warehouse_id",
    perform_request = FALSE
  )
  expect_s3_class(resp_query, "httr2_request")

  resp_cancel <- db_sql_exec_cancel(
    statement_id = "some_statement_id",
    perform_request = FALSE
  )
  expect_s3_class(resp_cancel, "httr2_request")

  resp_result <- db_sql_exec_result(
    statement_id = "some_statement_id",
    chunk_index = 0,
    perform_request = FALSE
  )
  expect_s3_class(resp_result, "httr2_request")

  resp_status <- db_sql_exec_status(
    statement_id = "some_statement_id",
    perform_request = FALSE
  )
  expect_s3_class(resp_status, "httr2_request")

})

skip_on_cran()
skip_unless_authenticated()
skip_unless_aws_workspace()

test_that("SQL Execution API", {

  # create a small serverless sql warehouse to issue queries against
  expect_no_error({
    random_id <- sample.int(100000, 1)
    test_warehouse <- db_sql_warehouse_create(
      name = paste0("brickster_test_warehouse_", random_id),
      cluster_size = "2X-Small",
      warehouse_type = "PRO",
      enable_serverless_compute = TRUE
    )
  })


  expect_no_error({
    resp_query <- db_sql_exec_query(
      statement = "select 1",
      warehouse_id = test_warehouse$id,
      wait_timeout = "0s"
    )
  })
  expect_type(resp_query, "list")
  expect_true(!is.null(resp_query$statement_id))
  expect_true(!is.null(resp_query$status$state))

  expect_no_error({
    resp_status <- db_sql_exec_status(
      statement_id = resp_query$statement_id
    )
  })
  expect_type(resp_status, "list")
  expect_true(!is.null(resp_query$statement_id))
  expect_true(!is.null(resp_query$status$state))

  expect_no_error({
    # wait for results to be available
    while (resp_status$status %in% c("PENDING", "RUNNING")) {
      Sys.sleep(1)
      resp_status <- db_sql_exec_status(
        statement_id = resp_query$statement_id
      )
    }
    # get results
    resp_result <- db_sql_exec_result(
      statement_id = resp_query$statement_id,
      chunk_index = 0
    )
  })
  expect_type(resp_status, "list")
  expect_identical(resp_result$data_array[[1]][[1]], "1")

  expect_no_error({
    resp_cancel <- db_sql_exec_cancel(
      statement_id = resp_query$statement_id
    )
  })
  expect_type(resp_cancel, "list")

  # cleanup/delete the warehouse used for testing
  expect_no_error({
    db_sql_warehouse_delete(
      id = test_warehouse$id
    )
  })


})
