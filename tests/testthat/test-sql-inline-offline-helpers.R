test_that("INLINE chunks decode schema types and preserve null positions", {
  columns <- list(
    list(name = "id", type_name = "INT"),
    list(name = "value", type_name = "DOUBLE"),
    list(name = "active", type_name = "BOOLEAN"),
    list(name = "day", type_name = "DATE"),
    list(name = "instant", type_name = "TIMESTAMP"),
    list(name = "big", type_name = "LONG"),
    list(name = "amount", type_name = "DECIMAL"),
    list(name = "bytes", type_name = "BINARY"),
    list(name = "text", type_name = "STRING")
  )
  rows <- list(
    list("1", "1.5", "true", "2024-01-02", "2024-01-02T03:04:05.125+02:00", "9223372036854775807", "12345678901234567890.123456789", "AP8=", ""),
    rep(list(NULL), length(columns)),
    list("2", "NaN", "false", "2024-01-03", "2024-01-02T01:04:05.125Z", "-9223372036854775808", "0.000000001", "", "last")
  )
  out <- db_sql_process_inline(list(data_array = rows), list(schema = list(columns = columns)))
  expect_identical(out$id, c(1L, NA_integer_, 2L))
  expect_equal(out$value, c(1.5, NA_real_, NaN))
  expect_identical(out$active, c(TRUE, NA, FALSE))
  expect_identical(out$day, as.Date(c("2024-01-02", NA, "2024-01-03")))
  expect_s3_class(out$instant, "POSIXct")
  expect_identical(attr(out$instant, "tzone"), "UTC")
  expect_equal(as.numeric(out$instant), c(1704157445.125, NA_real_, 1704157445.125))
  expect_identical(out$big, c("9223372036854775807", NA_character_, "-9223372036854775808"))
  expect_identical(out$amount, c("12345678901234567890.123456789", NA_character_, "0.000000001"))
  expect_identical(out$bytes, list(as.raw(c(0, 255)), NULL, raw()))
  expect_identical(out$text, c("", NA_character_, "last"))
  empty <- db_sql_process_inline(list(data_array = list()), list(schema = list(columns = columns)))
  expect_identical(empty, out[0, ])
})

test_that("db_sql_query follows every INLINE chunk using the statement endpoint", {
  state <- new.env(parent = emptyenv())
  state$chunks <- integer()
  local_mocked_bindings(
    db_sql_exec_and_wait = function(...) list(
      statement_id = "stmt-inline",
      manifest = list(total_row_count = 3, total_chunk_count = 3,
        schema = list(columns = list(list(name = "id", type_name = "INT")))),
      result = list(chunk_index = 0, row_count = 1, row_offset = 0,
                    data_array = list(list("1")), next_chunk_index = 1)
    ),
    db_perform_request = function(req) {
      path <- httr2::url_parse(req$url)$path
      index <- as.integer(tail(strsplit(path, "/", fixed = TRUE)[[1]], 1))
      state$chunks <- c(state$chunks, index)
      expect_identical(req$method, "GET")
      expect_identical(path, paste0("/api/2.0/sql/statements/stmt-inline/result/chunks/", index))
      list(chunk_index = index, row_count = 1, row_offset = index,
           data_array = list(list(as.character(index + 1L))), next_chunk_index = if (index == 1L) 2L else NULL)
    },
    .package = "brickster"
  )
  out <- db_sql_query("wh", "SELECT id", disposition = "INLINE", host = "mock_host", token = "mock_token", show_progress = FALSE)
  expect_identical(out$id, 1:3)
  expect_identical(state$chunks, 1:2)
})

test_that("INLINE row limits stop before fetching unneeded chunks", {
  state <- new.env(parent = emptyenv())
  state$chunks <- integer()
  local_mocked_bindings(
    db_sql_exec_result = function(statement_id, chunk_index, ...) {
      state$chunks <- c(state$chunks, chunk_index)
      list(chunk_index = 1L, row_offset = 2, row_count = 2,
           data_array = list(list("3"), list("4")), next_chunk_index = 2L)
    },
    .package = "brickster"
  )
  resp <- list(statement_id = "stmt-limit",
    manifest = list(total_row_count = 6, total_chunk_count = 3,
      schema = list(columns = list(list(name = "id", type_name = "INT")))),
    result = list(chunk_index = 0L, row_offset = 0, row_count = 2,
      data_array = list(list("1"), list("2")), next_chunk_index = 1L))
  expect_identical(db_sql_fetch_inline(resp, row_limit = 0, host = "h", token = "t"), tibble::tibble(id = integer()))
  expect_identical(db_sql_fetch_inline(resp, row_limit = 1, host = "h", token = "t")$id, 1L)
  expect_length(state$chunks, 0L)
  expect_identical(db_sql_fetch_inline(resp, row_limit = 3, host = "h", token = "t")$id, 1:3)
  expect_identical(state$chunks, 1L)
})

test_that("INLINE traversal rejects repeated chunk indices and incomplete results", {
  state <- new.env(parent = emptyenv())
  state$repeated <- TRUE
  local_mocked_bindings(
    db_sql_exec_result = function(...) list(chunk_index = 1L, row_offset = 1, row_count = 1,
      data_array = list(list("2")), next_chunk_index = if (state$repeated) 1L else NULL),
    .package = "brickster"
  )
  resp <- list(statement_id = "stmt-incomplete", manifest = list(total_row_count = 3,
    schema = list(columns = list(list(name = "id", type_name = "INT")))),
    result = list(chunk_index = 0L, row_offset = 0, row_count = 1,
      data_array = list(list("1")), next_chunk_index = 1L))
  expect_error(db_sql_fetch_inline(resp, host = "h", token = "t"), "repeated.*chunk")
  state$repeated <- FALSE
  expect_error(db_sql_fetch_inline(resp, host = "h", token = "t"), "ended.*3.*2")
})

test_that("INLINE integer extremes and timestamps without zones do not lose values", {
  manifest <- list(schema = list(columns = list(
    list(name = "lowest", type_name = "INT"),
    list(name = "local_time", type_name = "TIMESTAMP", type_text = "TIMESTAMP_NTZ")
  )))
  out <- db_sql_process_inline(list(data_array = list(list("-2147483648", "2024-01-02T03:04:05"))), manifest)
  expect_identical(out$lowest, -2147483648)
  expect_identical(out$local_time, "2024-01-02T03:04:05")
})

test_that("INLINE decoding rejects malformed rows and scalar values", {
  manifest <- list(schema = list(columns = list(list(name = "id", type_name = "INT"))))
  expect_error(db_sql_process_inline(list(data_array = list(list("1", "extra"))), manifest), "row width")
  expect_error(db_sql_process_inline(list(data_array = list(list("1.5"))), manifest), "decode.*id.*INT")
  manifest$schema$columns[[1]]$type_name <- "BOOLEAN"
  expect_error(db_sql_process_inline(list(data_array = list(list("invalid"))), manifest), "Invalid BOOLEAN")
})

test_that("INLINE chunk combination preserves duplicate column names", {
  local_mocked_bindings(
    db_sql_exec_result = function(...) list(chunk_index = 1L, row_offset = 1, row_count = 1, data_array = list(list("3", "4"))),
    .package = "brickster"
  )
  resp <- list(statement_id = "duplicates", manifest = list(total_row_count = 2,
    schema = list(columns = list(list(name = "id", type_name = "INT"), list(name = "id", type_name = "INT")))),
    result = list(chunk_index = 0L, row_offset = 0, row_count = 1, data_array = list(list("1", "2")), next_chunk_index = 1L))
  out <- db_sql_fetch_inline(resp, host = "h", token = "t")
  expect_identical(names(out), c("id", "id"))
  expect_identical(out[[1]], c(1L, 3L))
  expect_identical(out[[2]], c(2L, 4L))
})

test_that("INLINE traversal follows empty continuation chunks", {
  local_mocked_bindings(
    db_sql_exec_result = function(...) list(chunk_index = 1L, row_offset = 0,
      row_count = 1, data_array = list(list("1"))),
    .package = "brickster"
  )
  resp <- list(statement_id = "empty-first", manifest = list(total_row_count = 1,
    schema = list(columns = list(list(name = "id", type_name = "INT")))),
    result = list(chunk_index = 0L, row_offset = 0, row_count = 0,
      data_array = list(), next_chunk_index = 1L))
  expect_identical(db_sql_fetch_inline(resp, host = "h", token = "t")$id, 1L)
})

test_that("INLINE traversal rejects inconsistent chunk metadata", {
  resp <- list(statement_id = "bad-metadata", manifest = list(total_row_count = 1,
    schema = list(columns = list(list(name = "id", type_name = "INT")))),
    result = list(chunk_index = 0L, row_offset = 1, row_count = 1,
      data_array = list(list("1"))))
  expect_error(db_sql_fetch_inline(resp, host = "h", token = "t"), "offset")
  resp$result$row_offset <- 0
  resp$result$row_count <- 2
  expect_error(db_sql_fetch_inline(resp, host = "h", token = "t"), "row count")
})
