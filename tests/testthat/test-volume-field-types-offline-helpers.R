volume_types_connection <- function() {
  new(
    "DatabricksConnection", warehouse_id = "wh", host = "mock_host", token = "mock_token",
    catalog = "", schema = "", staging_volume = "/Volumes/c/s/v", show_progress = FALSE
  )
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
  value <- data.frame(
    id = 1:2, amount = c(1.2, 2.3), label = c("a", "b"),
    code = c("abc", "def"), fixed = c("x", "y")
  )
  value$items <- list(1:2, 3:4)
  purrr::walk(list("target", DBI::Id(schema = "s", table = "target"), I("target")), function(name) {
    expect_invisible(dbWriteTable(
      volume_types_connection(), name, value,
      field.types = c(
        items = "ARRAY<BIGINT>", fixed = "CHAR(5)", code = "VARCHAR(10)",
        amount = "DECIMAL(12, 2)", id = "BIGINT"
      ),
      overwrite = TRUE
    ))
  })
  expect_equal(state$uploads, 3L)
  expect_equal(state$cleanups, 3L)
  expect_length(state$sql, 6L)
  purrr::walk(state$sql[c(1L, 3L, 5L)], function(sql) {
    expect_match(sql, "^CREATE OR REPLACE TABLE")
    expect_match(sql, paste0(
      "(`id` BIGINT, `amount` DECIMAL(12, 2), `label` STRING, ",
      "`code` VARCHAR(10), `fixed` CHAR(5), `items` ARRAY<BIGINT>)"
    ), fixed = TRUE)
  })
  purrr::walk(state$sql[c(2L, 4L, 6L)], function(sql) {
    expect_match(sql, "^INSERT INTO")
    expect_match(sql, "(`id`, `amount`, `label`, `code`, `fixed`, `items`) SELECT * FROM READ_FILES(", fixed = TRUE)
  })
})

test_that("invalid volume field type arguments fail before staging", {
  local_mocked_bindings(
    dbExistsTable = function(...) FALSE,
    db_volume_dir_exists = function(...) stop("Unexpected staging lookup"),
    .package = "brickster"
  )
  invalid <- list(
    "BIGINT", c(missing = "BIGINT"), c(id = NA_character_), c(id = " "),
    c(id = "INT", id = "BIGINT"), c(id = 1), setNames("BIGINT", NA_character_)
  )
  purrr::walk(invalid, function(types) {
    expect_error(
      dbWriteTable(volume_types_connection(), "target", data.frame(id = 1), field.types = types),
      "field.types"
    )
  })
})

purrr::walk(c("CREATE", "INSERT"), function(failed_statement) {
  test_that(paste("volume writes clean up when", failed_statement, "fails"), {
    skip_if_not_installed("arrow")
    state <- new.env(parent = emptyenv())
    state$local_dir <- NULL
    state$cleaned <- FALSE
    state$sql <- character()
    local_mocked_bindings(
      dbExistsTable = function(...) FALSE,
      db_volume_dir_exists = function(...) TRUE,
      db_volume_dir_create = function(...) TRUE,
      db_volume_upload_dir = function(local_dir, ...) {
        state$local_dir <- local_dir
        TRUE
      },
      db_volume_dir_delete = function(...) {
        state$cleaned <- TRUE
        TRUE
      },
      db_sql_exec_and_wait = function(statement, ...) {
        state$sql <- c(state$sql, statement)
        if (startsWith(statement, failed_statement)) stop("Databricks rejected the write")
        list(status = list(state = "SUCCEEDED"))
      },
      .package = "brickster"
    )

    expect_error(
      dbWriteTable(volume_types_connection(), "target", data.frame(id = 1),
        field.types = c(id = "BIGINT")),
      "Databricks rejected the write"
    )
    expect_match(state$sql[[1]], "CREATE TABLE `target` (`id` BIGINT)", fixed = TRUE)
    expect_length(state$sql, if (failed_statement == "CREATE") 1L else 2L)
    expect_true(state$cleaned)
    expect_false(fs::dir_exists(state$local_dir))
  })
})
