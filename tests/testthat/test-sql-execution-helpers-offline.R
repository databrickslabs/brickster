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

test_that("db_sql_exec_poll_for_success returns on success", {
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
})

test_that("db_sql_exec_poll_for_success surfaces failures", {
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

test_that("db_sql_fetch_results uses fast path for one chunk", {
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
})

test_that("db_sql_fetch_results uses parallel path for multiple chunks", {
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

test_that("SQL submission rejects every unsuccessful terminal state", {
  state <- new.env(parent = emptyenv())
  state$status <- "CANCELED"
  local_mocked_bindings(
    db_sql_exec_query = function(...) list(statement_id = "stmt-1", status = list(state = state$status, error = list(message = "server {detail}"))),
    .package = "brickster"
  )
  purrr::walk(c("FAILED", "CANCELED", "CLOSED"), function(status) {
    state$status <- status
    expect_error(db_sql_exec_and_wait("wh", "SELECT 1", show_progress = FALSE), "server \\{detail\\}")
  })
})

test_that("SQL polling stops at its elapsed deadline without an extra status request", {
  state <- new.env(parent = emptyenv())
  state$elapsed <- 0
  state$calls <- 0L
  state$sleeps <- numeric()
  local_mocked_bindings(
    proc.time = function() c(elapsed = state$elapsed),
    Sys.sleep = function(seconds) {
      state$sleeps <- c(state$sleeps, seconds)
      state$elapsed <- state$elapsed + seconds
    },
    .package = "base"
  )
  local_mocked_bindings(
    db_sql_exec_status = function(...) {
      state$calls <- state$calls + 1L
      if (state$calls > 3L) stop("Polling failed to stop")
      list(status = list(state = "RUNNING"))
    },
    .package = "brickster"
  )
  expect_error(db_sql_exec_poll_for_success("stmt-timeout", interval = 10, poll_timeout = 2), "Timed out.*stmt-timeout")
  expect_identical(state$calls, 1L)
  expect_identical(state$sleeps, 2)
})

test_that("SQL submission time is deducted from the polling budget", {
  state <- new.env(parent = emptyenv())
  state$elapsed <- 0
  local_mocked_bindings(proc.time = function() c(elapsed = state$elapsed), .package = "base")
  local_mocked_bindings(
    db_sql_exec_query = function(...) {
      state$elapsed <- 3
      list(statement_id = "stmt-budget", status = list(state = "PENDING"))
    },
    db_sql_exec_poll_for_success = function(statement_id, poll_timeout, ...) {
      expect_identical(statement_id, "stmt-budget")
      expect_identical(poll_timeout, 2)
      list(status = list(state = "SUCCEEDED"))
    },
    .package = "brickster"
  )
  out <- db_sql_exec_and_wait("wh", "SELECT 1", poll_timeout = 5, show_progress = FALSE)
  expect_identical(out$status$state, "SUCCEEDED")
})

test_that("invalid polling limits are rejected before submission", {
  local_mocked_bindings(
    db_sql_exec_query = function(...) stop("Unexpected submission"),
    db_cluster_get = function(...) stop("Unexpected cluster request"),
    db_sql_warehouse_get = function(...) stop("Unexpected warehouse request"),
    db_context_command_run = function(...) stop("Unexpected command submission"),
    .package = "brickster"
  )
  purrr::walk(list(0, -1, NA_real_, -Inf, "1", c(1, 2)), function(timeout) {
    expect_error(db_sql_query("wh", "SELECT 1", poll_timeout = timeout, show_progress = FALSE), "poll_timeout")
    expect_error(get_and_start_cluster("cluster", poll_timeout = timeout), "poll_timeout")
    expect_error(get_and_start_warehouse("warehouse", poll_timeout = timeout), "poll_timeout")
    expect_error(db_context_command_run_and_wait("cluster", "context", poll_timeout = timeout), "poll_timeout")
  })
  expect_error(get_and_start_cluster("cluster", polling_interval = -1), "polling interval")
  expect_error(get_and_start_warehouse("warehouse", polling_interval = Inf), "polling interval")
})

test_that("unlimited SQL polling and late HTTP responses have explicit behavior", {
  state <- new.env(parent = emptyenv())
  state$elapsed <- 0
  local_mocked_bindings(proc.time = function() c(elapsed = state$elapsed), .package = "base")
  local_mocked_bindings(
    db_sql_exec_status = function(...) {
      state$elapsed <- state$elapsed + 100
      list(status = list(state = "SUCCEEDED"))
    },
    .package = "brickster"
  )
  expect_error(db_sql_exec_poll_for_success("late", poll_timeout = 5), "Timed out.*late")
  out <- db_sql_exec_poll_for_success("unlimited", poll_timeout = Inf)
  expect_identical(out$status$state, "SUCCEEDED")
})
