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
    chunk_index = 1,
    perform_request = FALSE
  )
  expect_s3_class(resp_result, "httr2_request")
  expect_identical(resp_result$method, "GET")
  expect_match(resp_result$url, "/api/2.0/sql/statements/some_statement_id/result/chunks/1$")

  resp_status <- db_sql_exec_status(
    statement_id = "some_statement_id",
    perform_request = FALSE
  )
  expect_s3_class(resp_status, "httr2_request")
})

test_that("SQL execution serializes named query tags as an API array", {
  req <- db_sql_exec_query(
    statement = "SELECT 1",
    warehouse_id = "wh-1",
    query_tags = list(team = "informatics", experiment = NULL, metadata = 'a:b,c\\d"e'),
    host = "mock.test",
    token = "mock-token",
    perform_request = FALSE
  )

  expect_s3_class(req, "httr2_request")
  expect_identical(req$method, "POST")
  expect_identical(req$url, "https://mock.test/api/2.0/sql/statements")
  body <- jsonlite::fromJSON(db_request_json(req), simplifyVector = FALSE)
  expect_identical(body$query_tags, list(
    list(key = "team", value = "informatics"),
    list(key = "experiment"),
    list(key = "metadata", value = 'a:b,c\\d"e')
  ))
  expect_identical(body$statement, "SELECT 1")
})

test_that("SQL execution keeps a single tag in an array and omits empty tags", {
  request <- function(...) db_sql_exec_query(
    "SELECT 1", "wh-1", host = "mock.test", token = "mock-token",
    perform_request = FALSE, ...
  )
  req <- request(query_tags = list(team = "informatics"))
  body <- jsonlite::fromJSON(db_request_json(req), simplifyVector = FALSE)
  expect_identical(body$query_tags, list(list(key = "team", value = "informatics")))

  purrr::walk(list(request(), request(query_tags = NULL), request(query_tags = list())), function(req) {
    expect_false("query_tags" %in% names(req$body$data))
  })
  tags <- setNames(as.list(rep("value", 20)), paste0("tag", seq_len(20)))
  expect_length(request(query_tags = tags)$body$data$query_tags, 20L)
})

test_that("SQL execution rejects malformed query tags before building a request", {
  invalid <- list(
    "team:informatics", c(team = "informatics"), data.frame(team = "informatics"),
    list("informatics"), list(team = "informatics", "dev"),
    setNames(list("value"), ""), setNames(list("value"), " "),
    setNames(list("value"), NA_character_), list(team = "a", team = "b"),
    list(team = NA_character_), list(team = 1), list(team = TRUE),
    list(team = character()), list(team = c("a", "b")), list(team = list("a")),
    setNames(as.list(rep("value", 21)), paste0("tag", seq_len(21)))
  )
  purrr::walk(invalid, function(tags) {
    expect_error(
      db_sql_exec_query("SELECT 1", "wh-1", query_tags = tags,
        host = "mock.test", token = "mock-token", perform_request = FALSE),
      "query_tags"
    )
  })
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
      wait_timeout = "0s",
      query_tags = list(application = "brickster_tests", test = "sql_execution")
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
      statement = "select 1",
      query_tags = list(application = "brickster_tests", test = "sql_query"),
      show_progress = FALSE
    )
  })
  expect_s3_class(resp_query, "tbl_df")

  expect_no_error({
    resp_query <- db_sql_query(
      warehouse_id = test_warehouse$id,
      statement = "select 1",
      return_arrow = TRUE,
      show_progress = FALSE
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

skip_on_cran()
skip_unless_authenticated()

# Set up test warehouse for db_sql_query tests
test_warehouse_id_sql <- tryCatch({
  create_test_warehouse()
}, error = function(e) {
  # Return NULL if warehouse creation fails
  NULL
})

# Skip all tests if warehouse creation failed
skip_if(is.null(test_warehouse_id_sql), "Could not create test warehouse")

# Set up cleanup on exit (only if warehouse was created successfully)
withr::defer({
  cleanup_test_warehouse(test_warehouse_id_sql)
}, testthat::teardown_env())

test_that("db_sql_query works as expected", {
  # Test basic query using the core function
  result <- db_sql_query(test_warehouse_id_sql, "SELECT 1 as test_col", show_progress = FALSE)
  expect_s3_class(result, "data.frame")
  expect_shape(result, nrow = 1)
  expect_equal(result$test_col, 1)
})

test_that("db_sql_query retrieves large INLINE results without losing rows", {
  result <- db_sql_query(
    test_warehouse_id_sql,
    "SELECT id, repeat('x', 200) AS s FROM range(100000) ORDER BY id",
    disposition = "INLINE",
    show_progress = FALSE
  )

  expect_equal(nrow(result), 100000L)
  expect_identical(result$id, as.character(0:99999))
  expect_true(all(nchar(result$s) == 200L))
})

test_that("db_sql_query handles complex queries", {
  # Test more complex query
  result <- db_sql_query(test_warehouse_id_sql, "SELECT 1 as a, 'test' as b, 3.14 as c", show_progress = FALSE)
  expect_s3_class(result, "data.frame")
  expect_shape(result, nrow = 1)
  expect_shape(result, ncol = 3)
  expect_equal(result$a, 1)
  expect_equal(result$b, "test")
  expect_equal(result$c, 3.14)
})

test_that("db_sql_query handles errors correctly", {
  # Test invalid SQL
  expect_error(
    db_sql_query(test_warehouse_id_sql, "INVALID SQL STATEMENT", show_progress = FALSE),
    "Query failed|PARSE_SYNTAX_ERROR"
  )
})

test_that("db_sql_query works with catalog and schema", {
  catalog <- "system"
  schema <- "information_schema"
  
  # Test query with catalog and schema context
  result <- db_sql_query(
    test_warehouse_id_sql, 
    "SELECT 1 as test",
    catalog = catalog,
    schema = schema,
    show_progress = FALSE
  )
  expect_s3_class(result, "data.frame")
  expect_equal(result$test, 1)
})
