test_that("oversized generated SQL fails before replacing the target table", {
  state <- new.env(parent = emptyenv())
  state$target <- "original rows"
  state$mutations <- 0L
  local_mocked_bindings(
    dbExistsTable = function(...) TRUE,
    dbExecute = function(...) {
      state$mutations <- state$mutations + 1L
      state$target <- "empty table"
      0L
    },
    db_sql_exec_and_wait = function(...) {
      state$mutations <- state$mutations + 1L
      stop("Server rejected oversized SQL")
    },
    .package = "brickster"
  )
  con <- new("DatabricksConnection", warehouse_id = "wh", host = "mock_host", token = "mock_token",
    catalog = "", schema = "", staging_volume = "", show_progress = FALSE)
  value <- data.frame(payload = strrep("'", 8 * 1024^2))
  failure <- tryCatch(dbWriteTable(con, "target", value, overwrite = TRUE), error = identity)
  expect_s3_class(failure, "brickster_sql_statement_too_large")
  expect_identical(state$target, "original rows")
  expect_identical(state$mutations, 0L)
})

test_that("write preflight reuses the validated SQL without serializing twice", {
  state <- new.env(parent = emptyenv())
  state$generated <- 0L
  state$events <- character()
  generate <- db_generate_typed_values_sql
  local_mocked_bindings(
    db_generate_typed_values_sql = function(conn, data) {
      state$generated <- state$generated + 1L
      state$events <- c(state$events, "serialize")
      generate(conn, data)
    },
    dbExecute = function(conn, statement, ...) {
      state$events <- c(state$events, "create")
      0L
    },
    db_sql_exec_and_wait = function(statement, ...) {
      state$events <- c(state$events, "insert")
      expect_match(statement, "INSERT INTO.*VALUES")
      list(status = list(state = "SUCCEEDED"))
    },
    .package = "brickster"
  )
  con <- new("DatabricksConnection", warehouse_id = "wh", host = "mock_host", token = "mock_token", catalog = "", schema = "")
  db_create_table_as_select_values(con, "`target`", data.frame(id = 1:2), field.types = NULL, overwrite = TRUE)
  expect_identical(state$generated, 1L)
  expect_identical(state$events, c("serialize", "create", "insert"))
})


test_that("serialization errors leave the existing target untouched", {
  local_mocked_bindings(
    dbExistsTable = function(...) TRUE,
    db_generate_typed_values_sql = function(...) stop("Unsupported input value"),
    dbExecute = function(...) stop("Must not replace the existing target"),
    db_sql_exec_and_wait = function(...) stop("Must not execute an insert"),
    .package = "brickster"
  )
  con <- new("DatabricksConnection", warehouse_id = "wh", host = "mock_host", token = "mock_token",
    catalog = "", schema = "", staging_volume = "", show_progress = FALSE)
  expect_error(dbWriteTable(con, "target", data.frame(id = 1), overwrite = TRUE), "Unsupported input value")
})
