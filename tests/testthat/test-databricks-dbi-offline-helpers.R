make_dbi_test_con <- function(
  staging_volume = "",
  disposition = "EXTERNAL_LINKS",
  show_progress = TRUE
) {
  new(
    "DatabricksConnection",
    warehouse_id = "test_warehouse",
    host = "test_host",
    token = "test_token",
    catalog = "test_catalog",
    schema = "test_schema",
    staging_volume = staging_volume,
    disposition = disposition,
    max_active_connections = 30,
    fetch_timeout = 300,
    show_progress = show_progress
  )
}

test_that("dbConnect validates tuning inputs and persists connection settings", {
  drv <- DatabricksSQL()
  state <- new.env(parent = emptyenv())
  state$opened <- FALSE

  local_mocked_bindings(
    db_sql_query = function(...) data.frame(test_connection = 1),
    dbi_connection_opened = function(conn) {
      state$opened <- TRUE
      invisible(TRUE)
    },
    .package = "brickster"
  )

  con <- dbConnect(
    drv,
    warehouse_id = "wh-1",
    host = "mock_host",
    token = "mock_token",
    disposition = "INLINE",
    max_active_connections = 12,
    fetch_timeout = 45,
    show_progress = FALSE
  )

  expect_s4_class(con, "DatabricksConnection")
  expect_identical(con@warehouse_id, "wh-1")
  expect_identical(con@disposition, "INLINE")
  expect_identical(con@max_active_connections, 12)
  expect_identical(con@fetch_timeout, 45)
  expect_false(con@show_progress)
  expect_true(state$opened)

  expect_error(
    dbConnect(
      drv,
      warehouse_id = "wh-1",
      host = "mock_host",
      token = "mock_token",
      max_active_connections = 0
    ),
    "`max_active_connections` must be a positive numeric value"
  )

  expect_error(
    dbConnect(
      drv,
      warehouse_id = "wh-1",
      host = "mock_host",
      token = "mock_token",
      fetch_timeout = 0
    ),
    "`fetch_timeout` must be a positive numeric value"
  )

  expect_error(
    dbConnect(
      drv,
      warehouse_id = "wh-1",
      host = "mock_host",
      token = "mock_token",
      show_progress = NA
    ),
    "`show_progress` must be `TRUE` or `FALSE`"
  )

  expect_error(
    dbConnect(
      drv,
      warehouse_id = "wh-1",
      host = "mock_host",
      token = "mock_token",
      disposition = "invalid"
    ),
    "'arg' should be one of"
  )
})

test_that("dbConnect preserves validation query error details", {
  drv <- DatabricksSQL()

  local_mocked_bindings(
    db_sql_query = function(...) {
      cli::cli_abort(c(
        "HTTP 403 Forbidden.",
        "i" = "PERMISSION_DENIED: You do not have permission to use the SQL Warehouse."
      ))
    },
    .package = "brickster"
  )

  expect_error(
    dbConnect(
      drv,
      warehouse_id = "wh-1",
      host = "mock_host",
      token = "mock_token"
    ),
    regexp = paste(
      "Failed to connect to warehouse",
      "HTTP 403 Forbidden",
      "PERMISSION_DENIED",
      sep = ".*"
    )
  )
})

test_that("dbConnect keeps dynamic CLI authentication refreshable", {
  drv <- DatabricksSQL()
  state <- new.env(parent = emptyenv())
  state$validation_token <- "not-called"

  local_mocked_bindings(
    db_sql_query = function(..., token) {
      state$validation_token <- token
      data.frame(test_connection = 1)
    },
    dbi_connection_opened = function(conn) invisible(TRUE),
    .package = "brickster"
  )

  con <- dbConnect(
    drv,
    warehouse_id = "wh-1",
    host = "workspace.example.com",
    token = NULL
  )

  expect_null(state$validation_token)
  expect_null(con@token)
})

test_that("dbWriteTable validates user input", {
  con <- make_dbi_test_con(staging_volume = "/Volumes/c/s/v")
  value <- data.frame(x = 1:3)

  expect_error(
    dbWriteTable(con, "tbl", value, overwrite = TRUE, append = TRUE),
    "Cannot specify both `overwrite = TRUE` and `append = TRUE`"
  )
  expect_error(
    dbWriteTable(con, "tbl", value, temporary = TRUE),
    "Temporary tables are not supported"
  )
  expect_error(
    dbWriteTable(con, "tbl", value[0, , drop = FALSE]),
    "Cannot write empty data frame"
  )
})

test_that("dbWriteTable routes to volume path when staging is preferred", {
  con <- make_dbi_test_con(staging_volume = "/Volumes/c/s/v")
  value <- data.frame(x = 1:3)
  state <- new.env(parent = emptyenv())
  state$path <- NULL
  state$show_progress <- NULL

  local_mocked_bindings(
    dbExistsTable = function(...) FALSE,
    db_should_use_volume_method = function(...) TRUE,
    db_write_table_volume = function(
      conn,
      quoted_name,
      value,
      staging_volume,
      append,
      show_progress,
      ...
    ) {
      state$path <- "volume"
      state$show_progress <- show_progress
      invisible(TRUE)
    },
    db_write_table_standard = function(...) {
      state$path <- "standard"
      invisible(TRUE)
    },
    .package = "brickster"
  )

  expect_invisible(
    dbWriteTable(
      con,
      "tbl_volume",
      value,
      overwrite = TRUE,
      show_progress = FALSE
    )
  )
  expect_identical(state$path, "volume")
  expect_false(state$show_progress)
})

test_that("dbWriteTable rejects progress argument name", {
  con <- make_dbi_test_con(staging_volume = "/Volumes/c/s/v")
  value <- data.frame(x = 1:3)

  expect_error(
    dbWriteTable(
      con,
      "tbl_volume",
      value,
      overwrite = TRUE,
      progress = FALSE
    ),
    "Argument `progress` is not supported; use `show_progress`"
  )
})

test_that("dbWriteTable routes to standard path when volume staging is not preferred", {
  con <- make_dbi_test_con(
    staging_volume = "/Volumes/c/s/v",
    show_progress = FALSE
  )
  value <- data.frame(x = 1:3)
  state <- new.env(parent = emptyenv())
  state$path <- NULL
  state$show_progress <- NULL

  local_mocked_bindings(
    dbExistsTable = function(...) FALSE,
    db_should_use_volume_method = function(...) FALSE,
    db_write_table_volume = function(...) {
      state$path <- "volume"
      invisible(TRUE)
    },
    db_write_table_standard = function(...) {
      args <- list(...)
      state$path <- "standard"
      state$show_progress <- args$show_progress
      invisible(TRUE)
    },
    .package = "brickster"
  )

  expect_invisible(dbWriteTable(con, "tbl_standard", value, overwrite = TRUE))
  expect_identical(state$path, "standard")
  expect_false(state$show_progress)
})

test_that("dbWriteTable standard path supports binary columns", {
  con <- make_dbi_test_con(show_progress = FALSE)
  value <- data.frame(id = 1:3)
  value$payload <- I(list(as.raw(c(0, 15, 255)), raw(0), NULL))
  state <- new.env(parent = emptyenv())
  state$sql <- character(0)

  local_mocked_bindings(
    dbExistsTable = function(...) FALSE,
    db_should_use_volume_method = function(...) FALSE,
    dbExecute = function(conn, statement, ...) {
      state$sql <- c(state$sql, statement)
      0L
    },
    db_sql_exec_and_wait = function(statement, ...) {
      state$sql <- c(state$sql, statement)
      list(status = list(state = "SUCCEEDED"))
    },
    .package = "brickster"
  )

  expect_invisible(dbWriteTable(con, "tbl_binary", value, overwrite = TRUE))
  expect_identical(
    state$sql[[1]],
    "CREATE OR REPLACE TABLE `tbl_binary` (`id` INT, `payload` BINARY)"
  )
  expect_identical(
    state$sql[[2]],
    paste0(
      "INSERT INTO `tbl_binary` (`id`, `payload`) VALUES ",
      "(1, X'000FFF'), (2, X''), (3, NULL)"
    )
  )
})

test_that("binary SQL serialization scans columns once rather than per cell", {
  con <- make_dbi_test_con()
  value <- data.frame(id = seq_len(20L))
  value$payload <- rep(list(as.raw(c(0, 255))), nrow(value))
  state <- new.env(parent = emptyenv())
  state$elements_scanned <- 0L
  original_is_binary <- db_is_binary_column

  local_mocked_bindings(
    db_is_binary_column = function(x) {
      state$elements_scanned <- state$elements_scanned + length(x)
      original_is_binary(x)
    },
    .package = "brickster"
  )

  sql <- db_generate_typed_values_sql(con, value)
  expected_rows <- purrr::map_chr(value$id, function(id) paste0("(", id, ", X'00FF')"))
  expect_identical(sql, paste(expected_rows, collapse = ", "))
  expect_lte(state$elements_scanned, ncol(value) * nrow(value))
})

test_that("db_format_typed_value_sql writes POSIXct as epoch microseconds", {
  con <- make_dbi_test_con(show_progress = FALSE)
  instant <- as.POSIXct("2024-07-01 08:00:00.123456", tz = "UTC")
  withr::local_envvar(TZ = "America/New_York")
  withr::local_options(list(digits.secs = 0, scipen = -9))

  purrr::walk(c("UTC", "America/New_York", "Europe/Berlin", ""), function(tz) {
    x <- instant
    attr(x, "tzone") <- tz
    expect_identical(
      db_format_typed_value_sql(con, x, x),
      "TIMESTAMP_MICROS(1719820800123456)"
    )
  })

  expect_identical(
    db_timestamp_literal(as.POSIXct("1900-06-15 12:00:00.5", tz = "UTC")),
    "TIMESTAMP_MICROS(-2194689599500000)"
  )
  expect_identical(
    db_generate_typed_values_sql(con, data.frame(ts = c(instant, NA))),
    "(TIMESTAMP_MICROS(1719820800123456)), (NULL)"
  )
})

test_that("timestamp SQL preserves microseconds and truncates submicroseconds", {
  values <- .POSIXct(c(
    1719820800.3, 1719820800.000001, 1719820800.123456,
    1735689599.9999996, 1104537600.000002,
    -0.3, -0.000001, -1.0000004, 0
  ), tz = "UTC")
  expected <- c(
    "1719820800300000", "1719820800000001", "1719820800123456",
    "1735689599999999", "1104537600000001",
    "-300000", "-1", "-1000000", "0"
  )

  expect_identical(
    purrr::map_chr(values, db_timestamp_literal),
    paste0("TIMESTAMP_MICROS(", expected, ")")
  )
})

test_that("inline timestamp SQL agrees with staged Parquet microseconds", {
  skip_if_not_installed("arrow")
  skip_if_not(arrow::codec_is_available("zstd"), "Arrow was built without zstd support")
  value <- data.frame(ts = .POSIXct(c(
    1719820800.3, 1719820800.000001, 1719820800.123456,
    1735689599.9999996, 1104537600.000002,
    -0.3, -0.000001, -1.0000004, 0, NA_real_
  ), tz = "Europe/Berlin"))
  path <- fs::file_temp("brickster-timestamps-")
  withr::defer(fs::dir_delete(path))
  arrow::write_dataset(value, path, format = "parquet", compression = "zstd")
  staged <- arrow::read_parquet(
    fs::dir_ls(path, glob = "*.parquet")[[1]],
    as_data_frame = FALSE
  )
  micros <- as.character(as.vector(staged$GetColumnByName("ts")$cast(arrow::int64())))
  expected_rows <- ifelse(
    is.na(micros), "(NULL)", paste0("(TIMESTAMP_MICROS(", micros, "))")
  )

  expect_identical(
    db_generate_typed_values_sql(make_dbi_test_con(), value),
    paste(expected_rows, collapse = ", ")
  )
})

test_that("dbAppendTable standard path supports binary columns", {
  con <- make_dbi_test_con(show_progress = FALSE)
  value <- data.frame(id = 4L)
  value$payload <- I(list(as.raw(171)))
  state <- new.env(parent = emptyenv())
  state$sql <- NULL

  local_mocked_bindings(
    dbExistsTable = function(...) TRUE,
    db_should_use_volume_method = function(...) FALSE,
    db_sql_exec_and_wait = function(statement, ...) {
      state$sql <- statement
      list(status = list(state = "SUCCEEDED"))
    },
    .package = "brickster"
  )

  expect_invisible(dbAppendTable(con, "tbl_binary", value))
  expect_identical(
    state$sql,
    "INSERT INTO `tbl_binary` (`id`, `payload`) VALUES (4, X'AB')"
  )
})

test_that("dbWriteTable handles row.names consistently for character and Id signatures", {
  con <- make_dbi_test_con()
  state <- new.env(parent = emptyenv())
  state$char_names <- NULL
  state$id_names <- NULL

  expect_error(
    dbWriteTable(
      con,
      "tbl",
      data.frame(.row_names = c("a", "b"), x = 1:2),
      row.names = TRUE,
      overwrite = TRUE
    ),
    "column \".row_names\" already exists"
  )

  local_mocked_bindings(
    dbExistsTable = function(...) FALSE,
    db_should_use_volume_method = function(...) FALSE,
    db_write_table_standard = function(conn, quoted_name, value, ...) {
      if (any(names(value) == ".row_names")) {
        state$char_names <- names(value)
      }
      if (any(names(value) == "row_names")) {
        state$id_names <- names(value)
      }
      invisible(TRUE)
    },
    .package = "brickster"
  )

  expect_invisible(
    dbWriteTable(
      con,
      "tbl_char",
      data.frame(x = 1:2),
      row.names = TRUE,
      overwrite = TRUE
    )
  )
  expect_identical(state$char_names, c(".row_names", "x"))

  expect_invisible(
    dbWriteTable(
      con,
      DBI::Id(catalog = "c", schema = "s", table = "t"),
      data.frame(x = 1:2),
      row.names = TRUE,
      overwrite = TRUE
    )
  )
  expect_identical(state$id_names, c("row_names", "x"))
})

test_that("dbListTables uses connection context when generating SQL", {
  state <- new.env(parent = emptyenv())
  state$sql <- character(0)

  local_mocked_bindings(
    dbGetQuery = function(conn, statement, ...) {
      state$sql <- c(state$sql, statement)
      if (grepl("test_catalog.test_schema", statement, fixed = TRUE)) {
        return(data.frame(tableName = "t_a"))
      }
      if (grepl("schema_only$", statement)) {
        return(data.frame(table_name = "t_b"))
      }
      data.frame(any_name = c("x", "y"))
    },
    .package = "brickster"
  )

  con <- make_dbi_test_con()
  expect_identical(dbListTables(con), "t_a")

  con_schema_only <- new(
    "DatabricksConnection",
    warehouse_id = "wh",
    host = "host",
    token = "token",
    catalog = "",
    schema = "schema_only",
    staging_volume = "",
    max_active_connections = 30,
    fetch_timeout = 300,
    show_progress = TRUE
  )
  expect_identical(dbListTables(con_schema_only), "t_b")

  con_global <- new(
    "DatabricksConnection",
    warehouse_id = "wh",
    host = "host",
    token = "token",
    catalog = "",
    schema = "",
    staging_volume = "",
    max_active_connections = 30,
    fetch_timeout = 300,
    show_progress = TRUE
  )
  expect_identical(dbListTables(con_global), c("x", "y"))

  expect_identical(state$sql, c(
    "SHOW TABLES IN test_catalog.test_schema",
    "SHOW TABLES IN schema_only",
    "SHOW TABLES"
  ))
})

test_that("dbListFields uses a zero-row query", {
  local_mocked_bindings(
    db_sql_query = function(statement, ...) {
      expect_identical(statement, "SELECT * FROM t LIMIT 0")
      tibble::tibble(id = integer())
    },
    .package = "brickster"
  )

  expect_identical(dbListFields(make_dbi_test_con(), "t"), "id")
})

test_that("dbRemoveTable and dbReadTable support character, Id, and AsIs inputs", {
  con <- make_dbi_test_con()
  state <- new.env(parent = emptyenv())
  state$drop_sql <- character(0)
  state$read_sql <- character(0)

  local_mocked_bindings(
    dbExecute = function(conn, statement, ...) {
      state$drop_sql <- c(state$drop_sql, statement)
      0L
    },
    dbGetQuery = function(conn, statement, ...) {
      state$read_sql <- c(state$read_sql, statement)
      data.frame(x = length(state$read_sql))
    },
    .package = "brickster"
  )

  dbRemoveTable(con, '"tbl_char"')
  dbRemoveTable(con, DBI::Id(catalog = "c", schema = "s", table = "t"))
  dbRemoveTable(con, I("asis_tbl"))

  expect_identical(state$drop_sql[[1]], "DROP TABLE tbl_char")
  expect_match(state$drop_sql[[2]], "DROP TABLE `c`\\.`s`\\.`t`")
  expect_identical(state$drop_sql[[3]], "DROP TABLE asis_tbl")

  out_char <- dbReadTable(con, '"tbl_char"')
  out_id <- dbReadTable(con, DBI::Id(catalog = "c", schema = "s", table = "t"))
  out_asis <- dbReadTable(con, I("asis_tbl"))

  expect_identical(out_char$x, 1L)
  expect_identical(out_id$x, 2L)
  expect_identical(out_asis$x, 3L)
  expect_identical(state$read_sql[[1]], "SELECT * FROM tbl_char")
  expect_match(state$read_sql[[2]], "SELECT \\* FROM `c`\\.`s`\\.`t`")
  expect_identical(state$read_sql[[3]], "SELECT * FROM asis_tbl")
})

test_that("query execution DBI methods dispatch expected options", {
  con <- make_dbi_test_con(staging_volume = "/Volumes/c/s/v")
  state <- new.env(parent = emptyenv())
  state$query_calls <- list()
  state$exec_calls <- list()
  state$next_id <- 0L

  local_mocked_bindings(
    db_sql_exec_query = function(...) {
      args <- list(...)
      state$next_id <- state$next_id + 1L
      state$query_calls[[length(state$query_calls) + 1L]] <- args
      list(statement_id = paste0("stmt-", state$next_id))
    },
    db_sql_query = function(...) {
      args <- list(...)
      state$query_calls[[length(state$query_calls) + 1L]] <- args
      data.frame(ok = TRUE)
    },
    db_sql_exec_and_wait = function(...) {
      args <- list(...)
      state$exec_calls[[length(state$exec_calls) + 1L]] <- args
      if (grepl("^DROP TABLE", args$statement)) {
        return(list(manifest = list()))
      }
      list(manifest = list(total_row_count = 5))
    },
    .package = "brickster"
  )

  res_query <- dbSendQuery(con, "SELECT 1")
  expect_s4_class(res_query, "DatabricksResult")
  expect_identical(res_query@statement_id, "stmt-1")

  res_stmt <- dbSendStatement(con, "SET spark.sql.shuffle.partitions = 1")
  expect_s4_class(res_stmt, "DatabricksResult")
  expect_identical(res_stmt@statement_id, "stmt-2")

  out_limit <- dbGetQuery(con, "SELECT * FROM some_table LIMIT 0")
  expect_identical(out_limit$ok, TRUE)

  out_regular <- dbGetQuery(con, "SELECT * FROM some_table", disposition = "EXTERNAL_LINKS")
  expect_identical(out_regular$ok, TRUE)

  rows_known <- dbExecute(con, "SELECT * FROM some_table")
  expect_identical(rows_known, 5L)

  rows_unknown <- dbExecute(con, "DROP TABLE IF EXISTS t")
  expect_identical(rows_unknown, 0L)

  expect_identical(state$query_calls[[1]]$wait_timeout, "0s")
  expect_identical(state$query_calls[[1]]$disposition, "EXTERNAL_LINKS")
  expect_identical(state$query_calls[[1]]$format, "ARROW_STREAM")
  expect_identical(state$query_calls[[2]]$wait_timeout, "0s")
  expect_identical(state$query_calls[[3]]$disposition, "INLINE")
  expect_false(state$query_calls[[3]]$show_progress)
  expect_identical(state$query_calls[[4]]$disposition, "EXTERNAL_LINKS")

  con_inline <- make_dbi_test_con(disposition = "INLINE")
  res_inline <- dbSendQuery(con_inline, "SELECT 2")
  expect_s4_class(res_inline, "DatabricksResult")
  expect_identical(state$query_calls[[5]]$disposition, "INLINE")
  expect_identical(state$query_calls[[5]]$format, "JSON_ARRAY")

  out_inline <- dbGetQuery(con_inline, "SELECT * FROM inline_table")
  expect_identical(out_inline$ok, TRUE)
  expect_identical(state$query_calls[[6]]$disposition, "INLINE")
})

test_that("query and fetch progress default to connection setting", {
  con <- make_dbi_test_con(show_progress = FALSE)
  state <- new.env(parent = emptyenv())
  state$query_progress <- NULL
  state$fetch_progress <- NULL

  local_mocked_bindings(
    db_sql_query = function(show_progress, ...) {
      state$query_progress <- c(state$query_progress, show_progress)
      data.frame(ok = TRUE)
    },
    db_sql_exec_status = function(...) {
      list(
        statement_id = "stmt-external",
        status = list(state = "SUCCEEDED"),
        manifest = list(
          format = "ARROW_STREAM",
          total_chunk_count = 1L,
          total_row_count = 1L,
          schema = list(columns = list(
            list(name = "ok", type_name = "BOOLEAN")
          ))
        ),
        result = list(external_links = list(
          list(external_link = "https://example.test/result")
        ))
      )
    },
    db_sql_fetch_results = function(show_progress, ...) {
      state$fetch_progress <- show_progress
      data.frame(ok = TRUE)
    },
    .package = "brickster"
  )

  expect_identical(dbGetQuery(con, "SELECT 1")$ok, TRUE)
  expect_identical(
    dbGetQuery(con, "SELECT 1", show_progress = TRUE)$ok,
    TRUE
  )

  res <- new(
    "DatabricksResult",
    statement_id = "stmt-external",
    statement = "SELECT 1",
    connection = con,
    completed = FALSE,
    rows_fetched = 0
  )
  expect_identical(dbFetch(res)$ok, TRUE)

  expect_identical(state$query_progress, c(FALSE, TRUE))
  expect_false(state$fetch_progress)
})

test_that("dbFetch processes inline results from dbSendQuery", {
  con <- make_dbi_test_con(disposition = "INLINE")
  res <- new(
    "DatabricksResult",
    statement_id = "stmt-inline",
    statement = "SELECT 1 UNION ALL SELECT 2",
    connection = con,
    completed = FALSE,
    rows_fetched = 0
  )

  local_mocked_bindings(
    db_sql_exec_status = function(...) {
      list(
        statement_id = "stmt-inline",
        status = list(state = "SUCCEEDED"),
        manifest = list(
          format = "JSON_ARRAY",
          total_chunk_count = 1L,
          total_row_count = 2L,
          schema = list(columns = list(
            list(name = "id", type_name = "INT")
          ))
        ),
        result = list(data_array = list(list(1L), list(2L)))
      )
    },
    db_sql_fetch_results_fast = function(...) {
      stop("external result fetcher should not be called")
    },
    .package = "brickster"
  )

  out <- dbFetch(res)

  expect_s3_class(out, "tbl_df")
  expect_identical(out$id, c(1L, 2L))
})

purrr::walk(c("JSON_ARRAY", "ARROW_STREAM"), function(format) {
  test_that(paste("dbFetch preserves empty result schema for", format), {
    fixture <- make_inline_test_result()
    fixture$response$manifest$format <- format
    fixture$response$manifest$total_row_count <- 0L
    fixture$response$manifest$total_chunk_count <- 0L
    fixture$response$manifest$chunks <- list()
    fixture$response$result <- list()
    res <- new(
      "DatabricksResult",
      statement_id = "stmt-empty",
      statement = "SELECT id, label FROM example WHERE FALSE",
      connection = make_dbi_test_con(show_progress = FALSE),
      completed = FALSE,
      rows_fetched = 0
    )

    local_mocked_bindings(
      db_sql_exec_status = function(...) fixture$response,
      db_perform_request = function(...) stop("unexpected result request"),
      .package = "brickster"
    )

    expect_identical(dbFetch(res), tibble::tibble(id = integer(), label = character()))
  })
})

purrr::walk(c("get", "fetch", "fetch-limited"), function(method) {
  test_that(paste("DBI INLINE retrieves multiple chunks with", method), {
    fixture <- make_inline_test_result()
    con <- make_dbi_test_con(show_progress = FALSE)
    con@host <- "dbi-inline.test"
    con@fetch_timeout <- 23
    state <- new.env(parent = emptyenv())
    state$chunks <- integer()

    local_mocked_bindings(
      db_sql_exec_query = function(disposition, format, ...) {
        expect_identical(disposition, "INLINE")
        expect_identical(format, "JSON_ARRAY")
        list(statement_id = "stmt-inline", status = list(state = "RUNNING"))
      },
      db_sql_exec_status = function(...) fixture$response,
      db_perform_request = function(req, ...) {
        index <- as.integer(sub(".*/chunks/", "", req$url))
        state$chunks <- c(state$chunks, index)
        expect_identical(
          req$url,
          paste0("https://dbi-inline.test/api/2.0/sql/statements/stmt-inline/result/chunks/", index)
        )
        expect_identical(rlang::wref_value(req$headers$Authorization), "Bearer test_token")
        expect_equal(req$options$timeout_ms, 23000)
        fixture$chunks[[index + 1L]]
      },
      .package = "brickster"
    )

    if (method == "get") {
      out <- dbGetQuery(con, "SELECT id, label FROM example", disposition = "INLINE")
    } else {
      res <- dbSendQuery(con, "SELECT id, label FROM example", disposition = "INLINE")
      out <- dbFetch(res, n = if (method == "fetch-limited") 3 else -1)
    }

    expected_rows <- if (method == "fetch-limited") 3L else 6L
    expect_s3_class(out, "tbl_df")
    expect_identical(out$id, as.character(seq_len(expected_rows) - 1L))
    expect_identical(
      out$label,
      list(NULL, NULL, "two", "three", NULL, "five")[seq_len(expected_rows)]
    )
    expect_identical(state$chunks, if (method == "fetch-limited") 1L else c(1L, 2L))
  })
})

test_that("volume-method selection warns/errors at size thresholds", {
  expect_true(db_should_use_volume_method(data.frame(x = 1), "/Volumes/c/s/v"))
  expect_false(db_should_use_volume_method(data.frame(x = 1), NULL, temporary = TRUE))
  expect_false(db_should_use_volume_method(data.frame(x = 1), NULL))

  expect_warning(
    expect_false(db_should_use_volume_method(data.frame(x = seq_len(20000)), NULL)),
    "will be slow"
  )

  expect_error(
    db_should_use_volume_method(data.frame(x = seq_len(60001)), NULL),
    "Cannot write 60001 rows without volume staging"
  )
})

test_that("db_write_table_volume errors when staging directory is missing", {
  testthat::skip_if_not_installed("arrow")
  con <- make_dbi_test_con()

  local_mocked_bindings(
    is_valid_volume_path = function(path) path,
    db_volume_dir_exists = function(...) FALSE,
    .package = "brickster"
  )

  expect_error(
    db_write_table_volume(
      conn = con,
      quoted_name = DBI::SQL("`tbl`"),
      value = data.frame(x = 1L),
      staging_volume = "/Volumes/c/s/v",
      append = FALSE,
      show_progress = FALSE
    ),
    "Staging volume directory does not exist"
  )
})

test_that("db_write_table_volume executes create flow when append is FALSE", {
  testthat::skip_if_not_installed("arrow")
  con <- make_dbi_test_con()
  state <- new.env(parent = emptyenv())
  state$sql <- NULL
  state$uploaded <- NULL
  state$deleted <- NULL

  local_mocked_bindings(
    is_valid_volume_path = function(path) path,
    db_volume_dir_exists = function(...) TRUE,
    db_volume_upload_dir = function(local_dir, volume_dir, ...) {
      state$uploaded <- volume_dir
      invisible(TRUE)
    },
    db_sql_exec_and_wait = function(statement, ...) {
      state$sql <- statement
      list(status = list(state = "SUCCEEDED"))
    },
    db_volume_dir_delete = function(path, recursive = FALSE, ...) {
      state$deleted <- path
      invisible(TRUE)
    },
    .package = "brickster"
  )
  local_mocked_bindings(
    write_dataset = function(dataset, path, ...) {
      fs::dir_create(path)
      writeLines("part", fs::path(path, "part-0.parquet"))
      invisible(NULL)
    },
    .package = "arrow"
  )

  expect_no_error(
    db_write_table_volume(
      conn = con,
      quoted_name = DBI::SQL("`tbl`"),
      value = data.frame(x = c(1L, 2L)),
      staging_volume = "/Volumes/c/s/v",
      append = FALSE,
      show_progress = FALSE
    )
  )

  expect_match(state$sql, "^CREATE TABLE .* AS SELECT \\* FROM READ_FILES")
  expect_identical(state$deleted, state$uploaded)
})

test_that("db_write_table_volume executes append flow when append is TRUE", {
  testthat::skip_if_not_installed("arrow")
  con <- make_dbi_test_con()
  state <- new.env(parent = emptyenv())
  state$sql <- NULL
  state$uploaded <- NULL
  state$deleted <- NULL

  local_mocked_bindings(
    is_valid_volume_path = function(path) path,
    db_volume_dir_exists = function(...) TRUE,
    db_volume_upload_dir = function(local_dir, volume_dir, ...) {
      state$uploaded <- volume_dir
      invisible(TRUE)
    },
    db_sql_exec_and_wait = function(statement, ...) {
      state$sql <- statement
      list(status = list(state = "SUCCEEDED"))
    },
    db_volume_dir_delete = function(path, recursive = FALSE, ...) {
      state$deleted <- path
      invisible(TRUE)
    },
    .package = "brickster"
  )
  local_mocked_bindings(
    write_dataset = function(dataset, path, ...) {
      fs::dir_create(path)
      writeLines("part", fs::path(path, "part-0.parquet"))
      invisible(NULL)
    },
    .package = "arrow"
  )

  expect_no_error(
    db_write_table_volume(
      conn = con,
      quoted_name = DBI::SQL("`tbl`"),
      value = data.frame(x = c(1L, 2L)),
      staging_volume = "/Volumes/c/s/v",
      append = TRUE,
      show_progress = FALSE
    )
  )

  expect_match(state$sql, "INSERT INTO `tbl` (`x`) SELECT * FROM READ_FILES(", fixed = TRUE)
  expect_identical(state$deleted, state$uploaded)
})
