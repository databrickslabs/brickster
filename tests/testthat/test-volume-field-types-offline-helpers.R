volume_types_connection <- function() {
  new("DatabricksConnection", warehouse_id = "wh", host = "mock_host", token = "mock_token",
    catalog = "", schema = "", staging_volume = "/Volumes/c/s/v", show_progress = FALSE)
}

test_that("volume writes carry partial field types through every table-name method", {
  skip_if_not_installed("arrow")
  state <- new.env(parent = emptyenv())
  state$sql <- character()
  state$uploads <- 0L
  state$cleanups <- 0L
  local_mocked_bindings(
    dbExistsTable = function(...) FALSE,
    db_volume_dir_exists = function(...) TRUE,
    db_volume_dir_create = function(...) TRUE,
    db_volume_upload_dir = function(local_dir, ...) {
      state$uploads <- state$uploads + 1L
      staged <- arrow::read_parquet(fs::dir_ls(local_dir, glob = "*.parquet")[[1]])
      expect_identical(staged$id, c(1L, 2L))
      TRUE
    },
    db_volume_dir_delete = function(...) {
      state$cleanups <- state$cleanups + 1L
      TRUE
    },
    db_sql_exec_and_wait = function(statement, ...) {
      state$sql <- c(state$sql, statement)
      list(status = list(state = "SUCCEEDED"))
    },
    .package = "brickster"
  )
  value <- data.frame(id = 1:2, amount = c(1.2, 2.3), label = c("a", "b"))
  purrr::walk(list("target", DBI::Id(schema = "s", table = "target"), I("target")), function(name) {
    expect_invisible(dbWriteTable(volume_types_connection(), name, value,
      field.types = c(id = "BIGINT", amount = "DECIMAL(12, 2)")))
  })
  expect_equal(state$uploads, 3L)
  expect_equal(state$cleanups, 3L)
  purrr::walk(state$sql, function(sql) {
    expect_match(sql, "SELECT CAST(`id` AS BIGINT) AS `id`, CAST(`amount` AS DECIMAL(12, 2)) AS `amount`, `label` FROM READ_FILES", fixed = TRUE)
  })
})

test_that("invalid or unsupported volume field types fail before staging", {
  local_mocked_bindings(
    dbExistsTable = function(...) FALSE,
    db_volume_dir_exists = function(...) stop("Unexpected staging lookup"),
    .package = "brickster"
  )
  purrr::walk(list("BIGINT", c(missing = "BIGINT"), c(id = NA_character_), c(id = ""),
    c(id = "INT", id = "BIGINT"), c(id = "VARCHAR(10)"), c(id = "STRUCT<x: INT>")), function(types) {
    expect_error(dbWriteTable(volume_types_connection(), "target", data.frame(id = 1), field.types = types), "field.types")
  })
})
