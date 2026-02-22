test_that("db_sql_query returns typed empty results from manifest schema", {
  local_mocked_bindings(
    db_sql_exec_and_wait = function(...) {
      list(
        statement_id = "stmt-1",
        manifest = list(
          total_row_count = 0,
          schema = list(columns = list(
            list(name = "id", type_name = "INT"),
            list(name = "name", type_name = "STRING"),
            list(name = "created_at", type_name = "TIMESTAMP")
          ))
        ),
        result = list()
      )
    },
    .package = "brickster"
  )

  out <- db_sql_query(
    warehouse_id = "wh-1",
    statement = "SELECT 1",
    show_progress = FALSE
  )

  expect_s3_class(out, "tbl_df")
  expect_identical(nrow(out), 0L)
  expect_identical(names(out), c("id", "name", "created_at"))
  expect_type(out$id, "integer")
  expect_type(out$name, "character")
  expect_s3_class(out$created_at, "POSIXct")
})

test_that("db_sql_query uses inline result processor for INLINE disposition", {
  state <- new.env(parent = emptyenv())
  state$inline_called <- FALSE

  local_mocked_bindings(
    db_sql_exec_and_wait = function(...) {
      list(
        statement_id = "stmt-2",
        manifest = list(total_row_count = 1),
        result = list(data_array = list(list(1L)))
      )
    },
    db_sql_process_inline = function(...) {
      state$inline_called <- TRUE
      tibble::tibble(v = 1L)
    },
    db_sql_fetch_results = function(...) stop("external processor should not be called"),
    .package = "brickster"
  )

  out <- db_sql_query(
    warehouse_id = "wh-2",
    statement = "SELECT 1",
    disposition = "INLINE",
    show_progress = FALSE
  )

  expect_true(state$inline_called)
  expect_identical(out$v, 1L)
})

test_that("db_sql_query uses external-links processor for EXTERNAL_LINKS disposition", {
  state <- new.env(parent = emptyenv())
  state$external_called <- FALSE

  local_mocked_bindings(
    db_sql_exec_and_wait = function(...) {
      list(
        statement_id = "stmt-3",
        manifest = list(total_row_count = 2),
        result = list()
      )
    },
    db_sql_fetch_results = function(...) {
      state$external_called <- TRUE
      tibble::tibble(v = c(1L, 2L))
    },
    db_sql_process_inline = function(...) stop("inline processor should not be called"),
    .package = "brickster"
  )

  out <- db_sql_query(
    warehouse_id = "wh-3",
    statement = "SELECT 1 UNION ALL SELECT 2",
    disposition = "EXTERNAL_LINKS",
    show_progress = FALSE
  )

  expect_true(state$external_called)
  expect_identical(out$v, c(1L, 2L))
})

test_that("db_sql_exec_poll_for_success returns on success and surfaces failures", {
  state <- new.env(parent = emptyenv())
  state$idx <- 0L
  states <- c("PENDING", "RUNNING", "SUCCEEDED")

  local_mocked_bindings(
    db_sql_exec_status = function(...) {
      state$idx <- state$idx + 1L
      list(status = list(state = states[[state$idx]]))
    },
    .package = "brickster"
  )

  out <- db_sql_exec_poll_for_success(
    statement_id = "stmt-1",
    interval = 0,
    show_progress = FALSE,
    host = "mock_host",
    token = "mock_token"
  )

  expect_identical(out$status$state, "SUCCEEDED")
  expect_identical(state$idx, 3L)

  local_mocked_bindings(
    db_sql_exec_status = function(...) {
      list(status = list(state = "FAILED", error = list(message = "detailed failure")))
    },
    .package = "brickster"
  )

  expect_error(
    db_sql_exec_poll_for_success(
      statement_id = "stmt-2",
      interval = 0,
      show_progress = FALSE
    ),
    "detailed failure"
  )
})

test_that("db_sql_fetch_results chooses fast or parallel paths by chunk count", {
  local_mocked_bindings(
    db_sql_fetch_results_fast = function(...) "fast-path",
    db_sql_fetch_results_parallel = function(...) stop("parallel path should not be used"),
    .package = "brickster"
  )

  out_fast <- db_sql_fetch_results(
    resp = list(statement_id = "stmt-fast", manifest = list(total_chunk_count = 1, total_row_count = 1)),
    show_progress = FALSE
  )
  expect_identical(out_fast, "fast-path")

  local_mocked_bindings(
    db_sql_fetch_results_fast = function(...) stop("fast path should not be used"),
    db_sql_fetch_results_parallel = function(...) "parallel-path",
    .package = "brickster"
  )

  out_parallel <- db_sql_fetch_results(
    resp = list(statement_id = "stmt-par", manifest = list(total_chunk_count = 3, total_row_count = 10)),
    show_progress = FALSE
  )
  expect_identical(out_parallel, "parallel-path")
})
