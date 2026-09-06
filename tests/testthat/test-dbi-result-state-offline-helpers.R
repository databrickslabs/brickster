dbi_cursor_connection <- function(disposition = "INLINE") {
  new("DatabricksConnection", warehouse_id = "wh", host = "mock_host", token = "mock_token",
    catalog = "", schema = "", disposition = disposition, show_progress = FALSE,
    max_active_connections = 2, fetch_timeout = 30)
}

dbi_cursor_response <- function() {
  list(statement_id = "cursor", status = list(state = "SUCCEEDED"),
    manifest = list(format = "JSON_ARRAY", total_chunk_count = 2L, total_row_count = 4L,
      schema = list(columns = list(list(name = "id", type_name = "INT")))),
    result = list(chunk_index = 0L, row_offset = 0L, row_count = 2L,
      data_array = list(list("1"), list("2")), next_chunk_index = 1L))
}

test_that("DBI cursors share state across copies and fetch successive rows once", {
  state <- new.env(parent = emptyenv())
  state$status_calls <- 0L
  state$chunk_calls <- 0L
  local_mocked_bindings(
    db_sql_exec_query = function(...) list(statement_id = "cursor", status = list(state = "PENDING")),
    db_sql_exec_status = function(...) {
      state$status_calls <- state$status_calls + 1L
      dbi_cursor_response()
    },
    db_sql_exec_result = function(...) {
      state$chunk_calls <- state$chunk_calls + 1L
      list(chunk_index = 1L, row_offset = 2L, row_count = 2L, data_array = list(list("3"), list("4")))
    },
    .package = "brickster"
  )
  res <- dbSendQuery(dbi_cursor_connection(), "SELECT id")
  alias <- res
  expect_false(dbHasCompleted(res))
  expect_identical(dbFetch(res, 0), tibble::tibble(id = integer()))
  expect_equal(dbGetRowCount(alias), 0)
  expect_false(dbHasCompleted(alias))
  expect_identical(dbFetch(res, 1)$id, 1L)
  expect_identical(dbFetch(alias, 1)$id, 2L)
  expect_equal(dbGetRowCount(res), 2)
  expect_identical(state$chunk_calls, 0L)
  expect_identical(dbFetch(res, Inf)$id, 3:4)
  expect_equal(dbGetRowCount(alias), 4)
  expect_true(dbHasCompleted(alias))
  expect_identical(dbFetch(alias), tibble::tibble(id = integer()))
  expect_identical(state$status_calls, 1L)
  expect_identical(state$chunk_calls, 1L)
})

test_that("clearing results and disconnecting connections persist across aliases", {
  local_mocked_bindings(
    db_sql_exec_query = function(...) dbi_cursor_response(),
    .package = "brickster"
  )
  con <- dbi_cursor_connection()
  alias <- con
  res <- dbSendQuery(con, "SELECT id")
  res_alias <- res
  expect_true(dbIsValid(res))
  expect_true(dbClearResult(res))
  expect_false(dbIsValid(res_alias))
  expect_error(dbFetch(res_alias), "closed|cleared")
  expect_warning(dbClearResult(res_alias), "already")
  expect_true(dbDisconnect(con))
  expect_false(dbIsValid(alias))
  expect_error(dbSendQuery(alias, "SELECT id"), "Connection.*valid|closed")
  expect_error(dbGetQuery(alias, "SELECT id"), "Connection.*valid|closed")
  expect_warning(dbDisconnect(alias), "already|invalid")
})

test_that("invalid fetch counts leave the cursor available for a valid fetch", {
  local_mocked_bindings(db_sql_exec_query = function(...) dbi_cursor_response(), .package = "brickster")
  res <- dbSendQuery(dbi_cursor_connection(), "SELECT id")
  purrr::walk(list(-2, 1.5, "1", numeric(), c(1, 2), NaN, -Inf, 1i), ~ expect_error(dbFetch(res, .x), "n.*must"))
  expect_identical(dbFetch(res, 1)$id, 1L)
  expect_equal(dbGetRowCount(res), 1)
})

test_that("a failed partial fetch does not advance the cursor past unreturned rows", {
  state <- new.env(parent = emptyenv())
  state$fail <- TRUE
  local_mocked_bindings(
    db_sql_exec_query = function(...) dbi_cursor_response(),
    db_sql_exec_result = function(...) {
      if (state$fail) stop("Chunk download failed")
      list(chunk_index = 1L, row_offset = 2, row_count = 2,
        data_array = list(list("3"), list("4")))
    },
    .package = "brickster"
  )
  res <- dbSendQuery(dbi_cursor_connection(), "SELECT id")
  expect_identical(dbFetch(res, 1)$id, 1L)
  expect_error(dbFetch(res, 3), "Chunk download failed")
  expect_equal(dbGetRowCount(res), 1)
  expect_identical(dbFetch(res, 1)$id, 2L)
  state$fail <- FALSE
  expect_identical(dbFetch(res, NA)$id, 3:4)
  expect_true(dbHasCompleted(res))
})

test_that("disconnect cancels pending results and releases all aliases independently", {
  state <- new.env(parent = emptyenv())
  state$sent <- 0L
  state$cancelled <- character()
  local_mocked_bindings(
    db_sql_exec_query = function(...) {
      state$sent <- state$sent + 1L
      list(statement_id = paste0("pending-", state$sent), status = list(state = "PENDING"))
    },
    db_sql_exec_cancel = function(statement_id, ...) {
      state$cancelled <- c(state$cancelled, statement_id)
      TRUE
    },
    .package = "brickster"
  )
  con <- dbi_cursor_connection()
  independent <- dbi_cursor_connection()
  first <- dbSendQuery(con, "SELECT 1")
  second <- dbSendQuery(con, "SELECT 2")
  third <- dbSendQuery(independent, "SELECT 3")
  expect_true(dbClearResult(first))
  expect_true(dbDisconnect(con))
  expect_false(dbIsValid(second))
  expect_true(dbIsValid(independent))
  expect_true(dbIsValid(third))
  expect_identical(state$cancelled, c("pending-1", "pending-2"))
  expect_error(dbFetch(second), "closed")
})

test_that("cancellation failures still invalidate the result and connection", {
  local_mocked_bindings(
    db_sql_exec_query = function(...) list(statement_id = "pending", status = list(state = "PENDING")),
    db_sql_exec_cancel = function(...) stop("Cancellation unavailable"),
    .package = "brickster"
  )
  con <- dbi_cursor_connection()
  res <- dbSendQuery(con, "SELECT id")
  expect_error(dbDisconnect(con), "cancellation.*failed")
  expect_false(dbIsValid(con))
  expect_false(dbIsValid(res))
  expect_warning(dbClearResult(res), "already cleared")
})

test_that("external DBI cursors download each chunk once and retain the selected disposition", {
  skip_if_not_installed("arrow")
  state <- new.env(parent = emptyenv())
  state$downloads <- integer()
  state$chunk_requests <- integer()
  local_mocked_bindings(
    db_sql_exec_query = function(disposition, ...) {
      expect_identical(disposition, "EXTERNAL_LINKS")
      resp <- dbi_cursor_response()
      resp$manifest$format <- "ARROW_STREAM"
      resp$result <- list(external_links = list(list(chunk_index = 0L, row_offset = 0,
        row_count = 2, external_link = "https://storage.test/0", next_chunk_index = 1L)))
      resp
    },
    db_sql_exec_status = function(...) stop("A completed status is already cached"),
    db_sql_exec_result = function(statement_id, chunk_index, ...) {
      state$chunk_requests <- c(state$chunk_requests, chunk_index)
      list(external_links = list(list(chunk_index = 1L, row_offset = 2,
        row_count = 2, external_link = "https://storage.test/1")))
    },
    db_sql_exec_cancel = function(...) stop("Completed statements must not be cancelled"),
    .package = "brickster"
  )
  local_mocked_bindings(
    req_perform_parallel = function(reqs, paths, ...) {
      expect_length(reqs, 1L)
      index <- as.integer(fs::path_file(httr2::url_parse(reqs[[1]]$url)$path))
      state$downloads <- c(state$downloads, index)
      arrow::write_ipc_stream(data.frame(id = index * 2L + 1:2), paths[[1]])
      list(httr2::response(200))
    },
    .package = "httr2"
  )
  res <- dbSendQuery(dbi_cursor_connection("INLINE"), "SELECT id", disposition = "EXTERNAL_LINKS")
  alias <- res
  expect_identical(dbFetch(res, 0)$id, integer())
  expect_identical(dbFetch(res, 1)$id, 1L)
  expect_identical(dbFetch(alias, 1)$id, 2L)
  expect_identical(state$downloads, 0L)
  expect_identical(dbFetch(res, 3)$id, 3:4)
  expect_identical(state$downloads, 0:1)
  expect_identical(state$chunk_requests, 1L)
  expect_equal(dbGetRowCount(alias), 4)
  expect_true(dbHasCompleted(alias))
  expect_identical(dbColumnInfo(alias)$name, "id")
  expect_true(dbClearResult(res))
})

test_that("failed SQL statements can be cleared without another request", {
  local_mocked_bindings(
    db_sql_exec_query = function(...) list(statement_id = "failed", status = list(
      state = "FAILED", error = list(message = "Invalid column"))),
    db_sql_exec_status = function(...) stop("Unexpected status request"),
    db_sql_exec_cancel = function(...) stop("Unexpected cancellation request"),
    .package = "brickster"
  )
  res <- dbSendQuery(dbi_cursor_connection(), "SELECT missing")
  expect_error(dbFetch(res), "FAILED.*Invalid column")
  expect_equal(dbGetRowCount(res), 0)
  expect_true(dbClearResult(res))
  expect_false(dbIsValid(res))
})

test_that("DBI chunk combination preserves duplicate names and promoted column types", {
  local_mocked_bindings(
    db_sql_exec_query = function(...) {
      resp <- dbi_cursor_response()
      resp$manifest$schema$columns <- list(list(name = "id", type_name = "INT"), list(name = "id", type_name = "BINARY"))
      resp$result$data_array <- list(list("-2147483648", "AA=="), list("2", NULL))
      resp
    },
    db_sql_exec_result = function(...) list(chunk_index = 1L, row_offset = 2, row_count = 2,
      data_array = list(list("3", ""), list("4", "AQ=="))),
    .package = "brickster"
  )
  res <- dbSendQuery(dbi_cursor_connection(), "SELECT id, bytes AS id")
  out <- dbFetch(res)
  expect_identical(names(out), c("id", "id"))
  expect_identical(out[[1]], c(-2147483648, 2, 3, 4))
  expect_identical(out[[2]], list(as.raw(0), NULL, raw(), as.raw(1)))
  expect_identical(dbFetch(res), out[0, ])
  expect_true(dbClearResult(res))
})
