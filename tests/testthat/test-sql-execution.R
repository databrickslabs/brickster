# Tests for SQL execution functionality including low-level API and high-level db_sql_query

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

  expect_no_error({
    resp_query <- db_sql_query(
      warehouse_id = test_warehouse$id,
      statement = "select 1"
    )
  })
  expect_s3_class(resp_query, "tbl_df")

  expect_no_error({
    resp_query <- db_sql_query(
      warehouse_id = test_warehouse$id,
      statement = "select 1",
      return_arrow = TRUE
    )
  })
  expect_s3_class(resp_query, c("Table", "ArrowTabular"))

  # cleanup/delete the warehouse used for testing
  expect_no_error({
    db_sql_warehouse_delete(
      id = test_warehouse$id
    )
  })
})

# Additional db_sql_query tests -----------------------------------------------

test_that("db_sql_query works as expected", {
  warehouse_id <- Sys.getenv("DATABRICKS_WAREHOUSE_ID")
  skip_if(nchar(warehouse_id) == 0, "No warehouse_id available")
  
  # Test basic query using the core function
  result <- db_sql_query(warehouse_id, "SELECT 1 as test_col")
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1)
  expect_equal(result$test_col, 1)
})

test_that("db_sql_query handles complex queries", {
  warehouse_id <- Sys.getenv("DATABRICKS_WAREHOUSE_ID")
  skip_if(nchar(warehouse_id) == 0, "No warehouse_id available")
  
  # Test more complex query
  result <- db_sql_query(warehouse_id, "SELECT 1 as a, 'test' as b, 3.14 as c")
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1)
  expect_equal(ncol(result), 3)
  expect_equal(result$a, 1)
  expect_equal(result$b, "test")
  expect_equal(result$c, 3.14)
})

test_that("db_sql_query handles errors correctly", {
  warehouse_id <- Sys.getenv("DATABRICKS_WAREHOUSE_ID")
  skip_if(nchar(warehouse_id) == 0, "No warehouse_id available")
  
  # Test invalid SQL
  expect_error(
    db_sql_query(warehouse_id, "INVALID SQL STATEMENT"),
    "Query failed|PARSE_SYNTAX_ERROR"
  )
})

test_that("db_sql_query works with catalog and schema", {
  warehouse_id <- Sys.getenv("DATABRICKS_WAREHOUSE_ID")
  catalog <- Sys.getenv("DATABRICKS_CATALOG")
  schema <- Sys.getenv("DATABRICKS_SCHEMA")
  
  skip_if(nchar(warehouse_id) == 0, "No warehouse_id available")
  skip_if(nchar(catalog) == 0 || nchar(schema) == 0, "No catalog/schema available")
  
  # Test query with catalog and schema context
  result <- db_sql_query(
    warehouse_id, 
    "SELECT 1 as test",
    catalog = catalog,
    schema = schema
  )
  expect_s3_class(result, "data.frame")
  expect_equal(result$test, 1)
})
