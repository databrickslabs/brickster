atomic_write_connection <- function() {
  new("DatabricksConnection", warehouse_id = "wh", host = "mock_host", token = "mock_token",
    catalog = "", schema = "", staging_volume = "", show_progress = FALSE)
}

test_that("failed replacement data leaves the existing table intact", {
  state <- new.env(parent = emptyenv())
  state$target <- "original rows"
  state$sql <- character()
  local_mocked_bindings(
    dbExistsTable = function(...) TRUE,
    db_sql_exec_and_wait = function(statement, ...) {
      state$sql <- c(state$sql, statement)
      if (grepl("VALUES", statement, fixed = TRUE)) stop("Server rejected replacement data")
      state$target <- "empty table"
      list(status = list(state = "SUCCEEDED"))
    },
    .package = "brickster"
  )
  expect_error(dbWriteTable(atomic_write_connection(), "target", data.frame(id = 1), overwrite = TRUE),
    "Server rejected replacement data")
  expect_identical(state$target, "original rows")
  expect_length(state$sql, 1L)
  expect_match(state$sql[[1]], "^CREATE OR REPLACE TABLE.*AS SELECT")
})

test_that("atomic replacement types every value and preserves declared scalar types", {
  state <- new.env(parent = emptyenv())
  state$sql <- character()
  local_mocked_bindings(
    dbExistsTable = function(...) TRUE,
    db_sql_exec_and_wait = function(statement, ...) {
      state$sql <- c(state$sql, statement)
      list(status = list(state = "SUCCEEDED"))
    },
    .package = "brickster"
  )
  value <- data.frame(id = c(1L, NA_integer_), amount = c(1.2, 123.45),
    label = c("x", "y"), day = as.Date(c("2026-01-01", NA)))
  value$payload <- I(list(as.raw(c(0, 255)), NULL))
  expect_invisible(dbWriteTable(atomic_write_connection(), DBI::Id(schema = "s", table = "t"),
    value, overwrite = TRUE, field.types = c(amount = "DECIMAL(12, 2)", id = "BIGINT")))
  expect_length(state$sql, 1L)
  expect_match(state$sql[[1]], "CREATE OR REPLACE TABLE `s`.`t` AS SELECT", fixed = TRUE)
  purrr::walk(c("CAST(1 AS BIGINT)", "CAST(NULL AS BIGINT)", "CAST(1.2 AS DECIMAL(12, 2))",
    "CAST('x' AS STRING)", "CAST('2026-01-01' AS DATE)", "CAST(X'00FF' AS BINARY)", "CAST(NULL AS BINARY)",
    "AS data (`id`, `amount`, `label`, `day`, `payload`)"), function(fragment) {
    expect_match(state$sql[[1]], fragment, fixed = TRUE)
  })
})

test_that("unsupported overwrite declarations fail before any mutating request", {
  state <- new.env(parent = emptyenv())
  state$mutations <- 0L
  local_mocked_bindings(
    dbExistsTable = function(...) TRUE,
    db_sql_exec_and_wait = function(...) {
      state$mutations <- state$mutations + 1L
      list(status = list(state = "SUCCEEDED"))
    },
    .package = "brickster"
  )
  purrr::walk(c("VARCHAR(10)", "CHAR(5)", "STRING NOT NULL", "ARRAY<INT>"), function(type) {
    expect_error(dbWriteTable(atomic_write_connection(), "target", data.frame(x = "a"),
      overwrite = TRUE, field.types = c(x = type)), "Atomic overwrite cannot preserve")
  })
  expect_identical(state$mutations, 0L)
})


test_that("ordinary creation retains explicit declarations and append stays a single insert", {
  state <- new.env(parent = emptyenv())
  state$exists <- FALSE
  state$sql <- character()
  local_mocked_bindings(
    dbExistsTable = function(...) state$exists,
    db_sql_exec_and_wait = function(statement, ...) {
      state$sql <- c(state$sql, statement)
      list(status = list(state = "SUCCEEDED"))
    },
    .package = "brickster"
  )
  con <- atomic_write_connection()
  expect_invisible(dbWriteTable(con, "target", data.frame(x = "a"), field.types = c(x = "VARCHAR(10)")))
  expect_identical(state$sql[[1]], "CREATE TABLE `target` (`x` VARCHAR(10))")
  expect_match(state$sql[[2]], "^INSERT INTO")
  state$exists <- TRUE
  expect_invisible(dbWriteTable(con, "target", data.frame(x = "b"), append = TRUE))
  expect_length(state$sql, 3L)
  expect_identical(state$sql[[3]], "INSERT INTO `target` (`x`) VALUES ('b')")
})
