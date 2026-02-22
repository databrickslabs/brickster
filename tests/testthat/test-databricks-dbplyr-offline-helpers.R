make_test_con <- function() {
  new(
    "DatabricksConnection",
    warehouse_id = "test_warehouse",
    host = "test_host",
    token = "test_token",
    catalog = "",
    schema = "",
    staging_volume = ""
  )
}

test_that("spark SQL translator handles Databricks-specific conditional, date, and aggregate branches", {
  con <- make_test_con()

  sql_if <- as.character(dbplyr::translate_sql(
    if_else(x > 0, 1L, 0L, -1L),
    con = con
  ))
  expect_match(sql_if, "IF\\(ISNULL", ignore.case = TRUE)

  sql_wday <- as.character(dbplyr::translate_sql(
    wday(x, label = TRUE, abbr = FALSE),
    con = con
  ))
  expect_match(sql_wday, "DATE_FORMAT", ignore.case = TRUE)
  expect_match(sql_wday, "EEEE")

  sql_floor_default <- as.character(dbplyr::translate_sql(
    floor_date(x, "unsupported_unit"),
    con = con
  ))
  expect_match(sql_floor_default, "DATE_TRUNC\\('day'", ignore.case = TRUE)

  sql_distinct_drop_na <- as.character(dbplyr::translate_sql(
    n_distinct(x, na.rm = TRUE),
    con = con,
    window = FALSE
  ))
  expect_match(sql_distinct_drop_na, "NANVL", ignore.case = TRUE)

  sql_weighted_mean <- as.character(dbplyr::translate_sql(
    weighted.mean(x, w),
    con = con,
    window = FALSE
  ))
  expect_match(sql_weighted_mean, "SUM\\(", ignore.case = TRUE)
  expect_match(sql_weighted_mean, "ISNULL", ignore.case = TRUE)
})

test_that("sql_query_fields emits LIMIT 0 wrapper", {
  con <- make_test_con()
  out <- dbplyr::sql_query_fields(con, "SELECT * FROM some_table")
  expect_match(as.character(out), "SELECT \\* FROM \\(SELECT \\* FROM some_table\\) LIMIT 0")
})

test_that("sql_query_save covers temporary and persistent branches", {
  con <- make_test_con()

  temp_sql <- with_mocked_bindings(
    dbplyr::sql_query_save(
      con = con,
      sql = "SELECT 1",
      name = "my_temp_view",
      temporary = TRUE
    ),
    generate_temp_name = function(prefix = "dbplyr_temp") {
      paste0(prefix, "_fixed")
    },
    .package = "brickster"
  )

  expect_match(temp_sql, "CREATE OR REPLACE TEMPORARY VIEW", ignore.case = TRUE)
  expect_match(temp_sql, "`my_temp_view_fixed`")

  table_sql <- dbplyr::sql_query_save(
    con = con,
    sql = "SELECT 1",
    name = DBI::SQL("`already_quoted`"),
    temporary = FALSE
  )

  expect_match(table_sql, "CREATE OR REPLACE TABLE", ignore.case = TRUE)
  expect_match(table_sql, "`already_quoted`")
})

test_that("sql_query_save validates connection", {
  con <- make_test_con()

  expect_error(
    with_mocked_bindings(
      dbplyr::sql_query_save(
        con = con,
        sql = "SELECT 1",
        name = "x",
        temporary = TRUE
      ),
      dbIsValid = function(dbObj, ...) FALSE,
      .package = "DBI"
    ),
    "Connection is not valid"
  )
})

test_that("copy_to dispatches dbWriteTable for temporary and persistent modes", {
  con <- make_test_con()
  state <- new.env(parent = emptyenv())
  state$calls <- list()

  local_mocked_bindings(
    dbIsValid = function(dbObj, ...) TRUE,
    dbWriteTable = function(dest, name, value, overwrite, temporary, ...) {
      state$calls[[length(state$calls) + 1L]] <- list(
        name = name,
        overwrite = overwrite,
        temporary = temporary,
        nrow = nrow(value)
      )
      TRUE
    },
    .package = "DBI"
  )
  local_mocked_bindings(
    tbl = function(src, from, ...) {
      structure(list(name = from), class = "tbl_dbi")
    },
    .package = "dplyr"
  )

  out_temp <- dplyr::copy_to(
    dest = con,
    df = data.frame(a = 1:2),
    name = "tmp_tbl",
    overwrite = TRUE,
    temporary = TRUE
  )
  expect_s3_class(out_temp, "tbl_dbi")

  out_persist <- dplyr::copy_to(
    dest = con,
    df = data.frame(a = 1:2),
    name = "persist_tbl",
    overwrite = FALSE,
    temporary = FALSE
  )
  expect_s3_class(out_persist, "tbl_dbi")

  expect_identical(length(state$calls), 2L)
  expect_true(state$calls[[1]]$temporary)
  expect_false(state$calls[[2]]$temporary)
  expect_identical(state$calls[[1]]$nrow, 2L)
  expect_identical(state$calls[[2]]$name, "persist_tbl")
})

test_that("copy_to rejects invalid destination connections", {
  con <- make_test_con()

  local_mocked_bindings(
    dbIsValid = function(dbObj, ...) FALSE,
    .package = "DBI"
  )

  expect_error(
    dplyr::copy_to(
      dest = con,
      df = data.frame(a = 1),
      name = "x",
      temporary = TRUE
    ),
    "Connection is not valid"
  )
})
