make_dbi_test_con <- function(staging_volume = "") {
  new(
    "DatabricksConnection",
    warehouse_id = "test_warehouse",
    host = "test_host",
    token = "test_token",
    catalog = "test_catalog",
    schema = "test_schema",
    staging_volume = staging_volume,
    max_active_connections = 30,
    fetch_timeout = 300
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
    max_active_connections = 12,
    fetch_timeout = 45
  )

  expect_s4_class(con, "DatabricksConnection")
  expect_identical(con@warehouse_id, "wh-1")
  expect_identical(con@max_active_connections, 12)
  expect_identical(con@fetch_timeout, 45)
  expect_true(state$opened)

  expect_error(
    dbConnect(
      drv,
      warehouse_id = "wh-1",
      host = "mock_host",
      token = "mock_token",
      max_active_connections = 0
    ),
    "max_active_connections must be a positive numeric value"
  )

  expect_error(
    dbConnect(
      drv,
      warehouse_id = "wh-1",
      host = "mock_host",
      token = "mock_token",
      fetch_timeout = 0
    ),
    "fetch_timeout must be a positive numeric value"
  )
})

test_that("dbWriteTable validates user input and routes standard vs volume paths", {
  con <- make_dbi_test_con(staging_volume = "/Volumes/c/s/v")
  value <- data.frame(x = 1:3)
  state <- new.env(parent = emptyenv())
  state$path <- NULL

  expect_error(
    dbWriteTable(con, "tbl", value, overwrite = TRUE, append = TRUE),
    "Cannot specify both overwrite = TRUE and append = TRUE"
  )
  expect_error(
    dbWriteTable(con, "tbl", value, temporary = TRUE),
    "Temporary tables are not supported"
  )
  expect_error(
    dbWriteTable(con, "tbl", value[0, , drop = FALSE]),
    "Cannot write empty data frame"
  )

  local_mocked_bindings(
    dbExistsTable = function(...) FALSE,
    db_should_use_volume_method = function(...) TRUE,
    db_write_table_volume = function(...) {
      state$path <- "volume"
      invisible(TRUE)
    },
    db_write_table_standard = function(...) {
      state$path <- "standard"
      invisible(TRUE)
    },
    .package = "brickster"
  )

  expect_invisible(dbWriteTable(con, "tbl_volume", value, overwrite = TRUE))
  expect_identical(state$path, "volume")

  local_mocked_bindings(
    dbExistsTable = function(...) FALSE,
    db_should_use_volume_method = function(...) FALSE,
    db_write_table_volume = function(...) {
      state$path <- "volume"
      invisible(TRUE)
    },
    db_write_table_standard = function(...) {
      state$path <- "standard"
      invisible(TRUE)
    },
    .package = "brickster"
  )

  expect_invisible(dbWriteTable(con, "tbl_standard", value, overwrite = TRUE))
  expect_identical(state$path, "standard")
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
    "column '.row_names' already exists"
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
      if (grepl("test_catalog\\.test_schema", statement)) {
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
    fetch_timeout = 300
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
    fetch_timeout = 300
  )
  expect_identical(dbListTables(con_global), c("x", "y"))

  expect_identical(state$sql, c(
    "SHOW TABLES IN test_catalog.test_schema",
    "SHOW TABLES IN schema_only",
    "SHOW TABLES"
  ))
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
  expect_identical(state$query_calls[[2]]$wait_timeout, "0s")
  expect_identical(state$query_calls[[3]]$disposition, "INLINE")
  expect_false(state$query_calls[[3]]$show_progress)
  expect_identical(state$query_calls[[4]]$disposition, "EXTERNAL_LINKS")
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

test_that("db_write_table_volume validates staging directory and executes create/append SQL", {
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
      progress = FALSE
    ),
    "Staging volume directory does not exist"
  )

  run_flow <- function(append) {
    state <- new.env(parent = emptyenv())
    state$sql <- NULL
    state$created <- NULL
    state$uploaded <- NULL
    state$deleted <- NULL

    local_mocked_bindings(
      is_valid_volume_path = function(path) path,
      db_volume_dir_exists = function(...) TRUE,
      db_volume_dir_create = function(path, ...) {
        state$created <- path
        invisible(TRUE)
      },
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
        append = append,
        progress = FALSE
      )
    )

    state
  }

  created <- run_flow(append = FALSE)
  expect_match(created$sql, "^CREATE OR REPLACE TABLE")
  expect_identical(created$created, created$uploaded)
  expect_identical(created$deleted, created$created)

  appended <- run_flow(append = TRUE)
  expect_match(appended$sql, "^COPY INTO")
  expect_identical(appended$created, appended$uploaded)
  expect_identical(appended$deleted, appended$created)
})
