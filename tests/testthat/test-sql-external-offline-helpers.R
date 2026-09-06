external_fetch_fixture <- function(chunk_count = 5L, chunk_rows = 2L) {
  list(statement_id = "stmt-external", manifest = list(
    total_chunk_count = chunk_count, total_row_count = chunk_count * chunk_rows,
    schema = list(columns = list(list(name = "id", type_name = "INT"))),
    chunks = purrr::map(seq_len(chunk_count) - 1L, ~ list(
      chunk_index = .x, row_offset = .x * chunk_rows, row_count = chunk_rows))))
}

test_that("external row limits select chunks before downloading to temporary files", {
  skip_if_not_installed("arrow")
  state <- new.env(parent = emptyenv())
  state$metadata <- integer()
  state$downloads <- integer()
  state$paths <- character()
  local_mocked_bindings(
    db_perform_request = function(req) {
      index <- as.integer(fs::path_file(httr2::url_parse(req$url)$path))
      state$metadata <- c(state$metadata, index)
      list(external_links = list(list(chunk_index = index,
        external_link = paste0("https://storage.test/", index))))
    },
    .package = "brickster"
  )
  local_mocked_bindings(
    req_perform_parallel = function(reqs, paths = NULL, ...) {
      purrr::map(seq_along(reqs), function(i) {
        index <- as.integer(fs::path_file(httr2::url_parse(reqs[[i]]$url)$path))
        state$downloads <- c(state$downloads, index)
        expect_null(reqs[[i]]$headers$Authorization)
        values <- data.frame(id = index * 2L + 1:2)
        state$paths <- c(state$paths, paths[[i]])
        arrow::write_ipc_stream(values, paths[[i]])
        httr2::response(200)
      })
    },
    .package = "httr2"
  )
  out <- db_sql_fetch_results(external_fetch_fixture(), row_limit = 3,
    host = "mock_host", token = "mock_token", show_progress = FALSE)
  expect_identical(out$id, 1:3)
  expect_identical(state$metadata, 0:1)
  expect_identical(state$downloads, 0:1)
  expect_length(state$paths, 2L)
  expect_false(any(fs::file_exists(state$paths)))
})

test_that("external zero-row reads do not resolve or download chunks", {
  local_mocked_bindings(
    req_perform_parallel = function(...) stop("Unexpected download"),
    req_perform = function(...) stop("Unexpected download"),
    .package = "httr2"
  )
  expect_identical(db_sql_fetch_results(external_fetch_fixture(), row_limit = 0,
    host = "h", token = "t", show_progress = FALSE), tibble::tibble(id = integer()))
})

test_that("dbplyr collection pushes finite limits down and warns only with evidence", {
  state <- new.env(parent = emptyenv())
  state$limits <- list()
  local_mocked_bindings(
    dbGetQuery = function(conn, statement, row_limit = NULL, ...) {
      state$limits[[length(state$limits) + 1L]] <- list(row_limit)
      data.frame(id = head(1:5, row_limit %||% 5))
    },
    .package = "brickster"
  )
  con <- new("DatabricksConnection", show_progress = FALSE)
  expect_warning(out <- dbplyr::db_collect(con, "SELECT id", n = 2), "Only first 2")
  expect_identical(out$id, 1:2)
  expect_no_warning(dbplyr::db_collect(con, "SELECT id", n = 5))
  expect_no_warning(dbplyr::db_collect(con, "SELECT id", n = 0, warn_incomplete = FALSE))
  expect_identical(state$limits, list(list(3), list(6), list(0)))
})

test_that("external downloads decode and remove each bounded batch before the next", {
  skip_if_not_installed("arrow")
  state <- new.env(parent = emptyenv())
  state$paths <- character()
  state$batch_sizes <- integer()
  state$events <- character()
  local_mocked_bindings(
    db_perform_request = function(req) {
      expect_false(any(fs::file_exists(state$paths)))
      index <- as.integer(fs::path_file(httr2::url_parse(req$url)$path))
      state$events <- c(state$events, paste0("metadata-", index))
      list(external_links = list(list(chunk_index = index,
        external_link = paste0("https://storage.test/", index))))
    },
    .package = "brickster"
  )
  local_mocked_bindings(
    req_perform_parallel = function(reqs, paths, ...) {
      state$batch_sizes <- c(state$batch_sizes, length(reqs))
      state$paths <- c(state$paths, paths)
      purrr::map(seq_along(reqs), function(i) {
        index <- as.integer(fs::path_file(httr2::url_parse(reqs[[i]]$url)$path))
        state$events <- c(state$events, paste0("download-", index))
        arrow::write_ipc_stream(data.frame(id = index * 2L + 1:2), paths[[i]])
        httr2::response(200)
      })
    },
    .package = "httr2"
  )
  out <- db_sql_fetch_results(external_fetch_fixture(), return_arrow = TRUE,
    max_active_connections = 2, host = "h", token = "t", show_progress = FALSE)
  expect_s3_class(out, "Table")
  expect_identical(as.data.frame(out)$id, 1:10)
  expect_identical(state$batch_sizes, c(2L, 2L, 1L))
  expect_identical(state$events[1:5], c("metadata-0", "metadata-1", "download-0", "download-1", "metadata-2"))
  expect_false(any(fs::file_exists(state$paths)))
})

test_that("nanoarrow fallback reads bounded files without manifest chunk offsets", {
  skip_if_not_installed("arrow")
  state <- new.env(parent = emptyenv())
  state$indices <- integer()
  local_mocked_bindings(
    db_perform_request = function(req) {
      index <- as.integer(fs::path_file(httr2::url_parse(req$url)$path))
      state$indices <- c(state$indices, index)
      list(external_links = list(list(chunk_index = index, row_count = 2,
        external_link = paste0("https://storage.test/", index))))
    },
    .package = "brickster"
  )
  local_mocked_bindings(
    req_perform_parallel = function(reqs, paths, ...) {
      expect_length(paths, 1L)
      index <- tail(state$indices, 1L)
      arrow::write_ipc_stream(data.frame(id = index * 2L + 1:2), paths[[1]])
      list(httr2::response(200))
    },
    .package = "httr2"
  )
  local_mocked_bindings(is_installed = function(...) FALSE, .package = "rlang")
  resp <- external_fetch_fixture()
  resp$manifest$chunks <- NULL
  out <- db_sql_fetch_results(resp, row_limit = 3, host = "h", token = "t", show_progress = FALSE)
  expect_identical(out$id, 1:3)
  expect_identical(state$indices, 0:1)
})

test_that("single-chunk fetch refreshes an expired link before downloading", {
  skip_if_not_installed("arrow")
  state <- new.env(parent = emptyenv())
  state$refreshed <- 0L
  local_mocked_bindings(
    db_perform_request = function(req) {
      state$refreshed <- state$refreshed + 1L
      expect_match(req$url, "/result/chunks/0$")
      list(external_links = list(list(chunk_index = 0, external_link = "https://storage.test/fresh")))
    },
    .package = "brickster"
  )
  local_mocked_bindings(
    req_perform_parallel = function(reqs, paths, ...) {
      expect_identical(reqs[[1]]$url, "https://storage.test/fresh")
      arrow::write_ipc_stream(data.frame(id = 1:2), paths[[1]])
      list(httr2::response(200))
    },
    .package = "httr2"
  )
  resp <- external_fetch_fixture(chunk_count = 1L)
  resp$result <- list(external_links = list(list(chunk_index = 0,
    external_link = "https://storage.test/expired", expiration = "2000-01-01T00:00:00Z")))
  expect_identical(db_sql_fetch_results(resp, row_limit = 1, host = "h", token = "t", show_progress = FALSE)$id, 1L)
  expect_identical(state$refreshed, 1L)
})

test_that("failed external downloads remove partial temporary files", {
  state <- new.env(parent = emptyenv())
  state$paths <- character()
  local_mocked_bindings(
    req_perform_parallel = function(reqs, paths, ...) {
      state$paths <- paths
      fs::file_create(paths)
      stop("Download interrupted")
    },
    .package = "httr2"
  )
  resp <- external_fetch_fixture(chunk_count = 1L)
  resp$result <- list(external_links = list(list(chunk_index = 0, external_link = "https://storage.test/0")))
  expect_error(db_sql_fetch_results(resp, host = "h", token = "t", show_progress = FALSE), "Download interrupted")
  expect_length(state$paths, 1L)
  expect_false(any(fs::file_exists(state$paths)))
  expect_false(any(fs::dir_exists(fs::path_dir(state$paths))))
})

test_that("dbFetch forwards zero-row external reads without downloading", {
  local_mocked_bindings(
    db_sql_exec_status = function(...) {
      resp <- external_fetch_fixture()
      resp$status <- list(state = "SUCCEEDED")
      resp$manifest$format <- "ARROW_STREAM"
      resp
    },
    db_perform_request = function(...) stop("Unexpected chunk request"),
    .package = "brickster"
  )
  res <- new("DatabricksResult", statement_id = "stmt", completed = FALSE,
    connection = new("DatabricksConnection", host = "h", token = "t", disposition = "EXTERNAL_LINKS", show_progress = FALSE))
  expect_identical(dbFetch(res, n = 0), tibble::tibble(id = integer()))
})

test_that("external downloads reject missing manifest rows before requesting chunks", {
  local_mocked_bindings(
    db_perform_request = function(...) stop("Unexpected chunk request"),
    .package = "brickster"
  )
  resp <- external_fetch_fixture()
  resp$manifest$chunks[[2]]$row_offset <- 3
  expect_error(db_sql_fetch_results(resp, host = "h", token = "t", show_progress = FALSE), "missing rows")
})
