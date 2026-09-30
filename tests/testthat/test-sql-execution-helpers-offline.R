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
    db_sql_fetch_results_fast = function(...) stop("external processor should not be called"),
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

purrr::walk(
  list(
    list(limit = NULL, ids = as.character(0:5), chunks = c(1L, 2L)),
    list(limit = 1L, ids = "0", chunks = integer()),
    list(limit = 2L, ids = c("0", "1"), chunks = integer()),
    list(limit = 3L, ids = c("0", "1", "2"), chunks = 1L),
    list(limit = 4L, ids = as.character(0:3), chunks = 1L),
    list(limit = 6L, ids = as.character(0:5), chunks = c(1L, 2L)),
    list(limit = 8L, ids = as.character(0:5), chunks = c(1L, 2L))
  ),
  function(case) {
    limit_label <- if (is.null(case$limit)) "all rows" else case$limit
    test_that(paste("INLINE query fetches ordered chunks for limit", limit_label), {
      fixture <- make_inline_test_result()
      state <- new.env(parent = emptyenv())
      state$chunks <- integer()

      local_mocked_bindings(
        db_sql_exec_and_wait = function(...) fixture$response,
        db_perform_request = function(req, ...) {
          index <- as.integer(sub(".*/chunks/", "", req$url))
          state$chunks <- c(state$chunks, index)
          expect_identical(req$method, "GET")
          expect_identical(
            req$url,
            paste0("https://inline.test/api/2.0/sql/statements/stmt-inline/result/chunks/", index)
          )
          expect_identical(rlang::wref_value(req$headers$Authorization), "Bearer inline-token")
          expect_equal(req$options$timeout_ms, 17000)
          fixture$chunks[[index + 1L]]
        },
        .package = "brickster"
      )

      out <- db_sql_query(
        warehouse_id = "wh-inline",
        statement = "SELECT id, label FROM example",
        disposition = "INLINE",
        row_limit = case$limit,
        fetch_timeout = 17,
        host = "inline.test",
        token = "inline-token",
        show_progress = FALSE
      )

      expect_s3_class(out, "tbl_df")
      expect_identical(out$id, case$ids)
      expect_identical(
        out$label,
        list(NULL, NULL, "two", "three", NULL, "five")[seq_along(case$ids)]
      )
      expect_identical(state$chunks, case$chunks)
    })
  }
)

test_that("single-chunk INLINE results require no additional requests", {
  fixture <- make_inline_test_result()
  fixture$response$manifest$total_chunk_count <- 1L
  fixture$response$manifest$total_row_count <- 2L
  fixture$response$manifest$chunks <- fixture$response$manifest$chunks[1]
  fixture$response$result$next_chunk_index <- NULL

  local_mocked_bindings(
    db_sql_exec_and_wait = function(...) fixture$response,
    db_perform_request = function(...) stop("unexpected chunk request"),
    .package = "brickster"
  )

  out <- db_sql_query("wh-inline", "SELECT 1", disposition = "INLINE", show_progress = FALSE)
  expect_identical(out$id, c("0", "1"))
  expect_identical(out$label, list(NULL, NULL))
})

test_that("empty INLINE results retain schema without fetching chunks", {
  fixture <- make_inline_test_result()
  fixture$response$manifest$total_chunk_count <- 0L
  fixture$response$manifest$total_row_count <- 0L
  fixture$response$manifest$chunks <- list()
  fixture$response$result <- list()

  local_mocked_bindings(
    db_sql_exec_and_wait = function(...) fixture$response,
    db_perform_request = function(...) stop("unexpected chunk request"),
    .package = "brickster"
  )

  out <- db_sql_query("wh-inline", "SELECT 1 WHERE FALSE", disposition = "INLINE", show_progress = FALSE)
  expect_identical(out, tibble::tibble(id = integer(), label = character()))
})

test_that("INLINE chunk request failures propagate instead of returning partial rows", {
  fixture <- make_inline_test_result()

  local_mocked_bindings(
    db_sql_exec_and_wait = function(...) fixture$response,
    db_perform_request = function(...) stop("chunk retrieval failed"),
    .package = "brickster"
  )

  expect_error(
    db_sql_query(
      "wh-inline", "SELECT 1", disposition = "INLINE",
      host = "inline.test", token = "inline-token", show_progress = FALSE
    ),
    "chunk retrieval failed"
  )
})

test_that("INLINE results fail when fetched rows do not satisfy the manifest", {
  fixture <- make_inline_test_result()
  fixture$chunks[[3]]$data_array <- list(list("4", NULL))

  local_mocked_bindings(
    db_sql_exec_and_wait = function(...) fixture$response,
    db_perform_request = function(req, ...) {
      index <- as.integer(sub(".*/chunks/", "", req$url))
      fixture$chunks[[index + 1L]]
    },
    .package = "brickster"
  )

  expect_error(
    db_sql_query(
      "wh-inline", "SELECT 1", disposition = "INLINE", fetch_timeout = NULL,
      host = "inline.test", token = "inline-token", show_progress = FALSE
    ),
    "Received 5 INLINE result rows, but expected 6"
  )
})

test_that("db_sql_query uses external-links processor for EXTERNAL_LINKS disposition", {
  state <- new.env(parent = emptyenv())
  state$external_called <- FALSE

  local_mocked_bindings(
    db_sql_exec_and_wait = function(...) {
      list(
        statement_id = "stmt-3",
        manifest = list(format = "ARROW_STREAM", total_row_count = 2, total_chunk_count = 1),
        result = list()
      )
    },
    db_sql_fetch_results_fast = function(...) {
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
