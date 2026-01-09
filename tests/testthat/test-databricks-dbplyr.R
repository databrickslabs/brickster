# Load brickster package for class definitions and functions
# Avoid loading dbplyr, dplyr etc. to prevent startup messages
library(brickster)

# Offline Tests (no warehouse connection required) ---------------------------

test_that("dbplyr edition declaration works offline", {
  # Create connection object for testing (not through dbConnect)
  con <- new(
    "DatabricksConnection",
    warehouse_id = "test_warehouse",
    host = "test_host",
    token = "test_token",
    catalog = "",
    schema = "",
    staging_volume = ""
  )

  edition <- dbplyr::dbplyr_edition(con)
  expect_equal(edition, 2L)
})

test_that("String function translations work offline", {
  con <- new(
    "DatabricksConnection",
    warehouse_id = "test_warehouse",
    host = "test_host",
    token = "test_token",
    catalog = "",
    schema = "",
    staging_volume = ""
  )

  # Test basic string translations without executing
  expect_match(
    as.character(dbplyr::translate_sql(paste("a", "b"), con = con)),
    "concat",
    ignore.case = TRUE
  )
})

test_that("Aggregation function translations work offline", {
  con <- new(
    "DatabricksConnection",
    warehouse_id = "test_warehouse",
    host = "test_host",
    token = "test_token",
    catalog = "",
    schema = "",
    staging_volume = ""
  )

  # Test aggregation translations without executing
  expect_match(
    as.character(dbplyr::translate_sql(dplyr::n(), con = con, window = FALSE)),
    "count\\(\\*\\)",
    ignore.case = TRUE
  )
  expect_match(
    as.character(dbplyr::translate_sql(
      mean(x, na.rm = TRUE),
      con = con,
      window = FALSE
    )),
    "avg",
    ignore.case = TRUE
  )
})

test_that("Identifier escaping uses backticks", {
  con <- new(
    "DatabricksConnection",
    warehouse_id = "test_warehouse",
    host = "test_host",
    token = "test_token",
    catalog = "",
    schema = "",
    staging_volume = ""
  )

  # Test identifier escaping
  escaped <- DBI::dbQuoteIdentifier(con, "my_table")
  expect_match(as.character(escaped), "`")
  expect_match(as.character(escaped), "my_table")

  # Test SQL object passthrough
  sql_obj <- DBI::SQL("already_quoted")
  escaped_sql <- DBI::dbQuoteIdentifier(con, sql_obj)
  expect_identical(escaped_sql, sql_obj)
})

test_that("String escaping uses single quotes", {
  con <- new(
    "DatabricksConnection",
    warehouse_id = "test_warehouse",
    host = "test_host",
    token = "test_token",
    catalog = "",
    schema = "",
    staging_volume = ""
  )

  # Test string escaping
  escaped <- DBI::dbQuoteString(con, "test string")
  expect_match(as.character(escaped), "'")
  expect_match(as.character(escaped), "test string")
})

test_that("sql_query_save validates inputs offline", {
  con <- new(
    "DatabricksConnection",
    warehouse_id = "test_warehouse",
    host = "test_host",
    token = "test_token",
    catalog = "",
    schema = "",
    staging_volume = ""
  )

  # Test input validation
  expect_error(
    dbplyr::sql_query_save(con, "", "temp_table"),
    "SQL query must be provided and non-empty"
  )

  expect_error(
    dbplyr::sql_query_save(con, "SELECT 1", ""),
    "Table/view name must be provided and non-empty"
  )
})


test_that("copy_to validates inputs offline", {
  con <- new(
    "DatabricksConnection",
    warehouse_id = "test_warehouse",
    host = "test_host",
    token = "test_token",
    catalog = "",
    schema = "",
    staging_volume = ""
  )

  # Test input validation
  expect_error(
    copy_to.DatabricksConnection(con, "not_a_dataframe"),
    "df must be a data frame"
  )

  expect_error(
    copy_to.DatabricksConnection(con, data.frame()),
    "Cannot copy empty data frame"
  )
})

test_that("Temporary name generation works correctly", {
  # Test basic name generation
  name1 <- generate_temp_name()
  name2 <- generate_temp_name()

  expect_match(name1, "^dbplyr_temp_")
  expect_match(name2, "^dbplyr_temp_")
  expect_false(name1 == name2) # Should be unique

  # Test custom prefix
  custom_name <- generate_temp_name("custom_prefix")
  expect_match(custom_name, "^custom_prefix_")
})


test_that("SQL table analyze generates correct SQL", {
  con <- new(
    "DatabricksConnection",
    warehouse_id = "test_warehouse",
    host = "test_host",
    token = "test_token",
    catalog = "",
    schema = "",
    staging_volume = ""
  )

  sql <- dbplyr::sql_table_analyze(con, "test_table")
  expect_match(as.character(sql), "ANALYZE TABLE")
  expect_match(as.character(sql), "test_table")
  expect_match(as.character(sql), "COMPUTE STATISTICS")
})

# Online Tests (require warehouse connection) --------------------------------

skip_on_cran()
skip_unless_authenticated()

# Set up test warehouse for all dbplyr tests
test_warehouse_id_dbplyr <- tryCatch(
  {
    create_test_warehouse()
  },
  error = function(e) {
    # Return NULL if warehouse creation fails
    NULL
  }
)

# Skip all tests if warehouse creation failed
skip_if(is.null(test_warehouse_id_dbplyr), "Could not create test warehouse")

# Set up cleanup on exit (only if warehouse was created successfully)
withr::defer(
  {
    cleanup_test_warehouse(test_warehouse_id_dbplyr)
  },
  testthat::teardown_env()
)

test_that("dbplyr edition is correctly declared with live connection", {
  drv <- DatabricksSQL()

  con <- DBI::dbConnect(drv, warehouse_id = test_warehouse_id_dbplyr)
  edition <- dbplyr::dbplyr_edition(con)
  expect_equal(edition, 2L)

  DBI::dbDisconnect(con)
})

test_that("String function translations work with live connection", {
  drv <- DatabricksSQL()

  con <- DBI::dbConnect(drv, warehouse_id = test_warehouse_id_dbplyr)

  # Test basic string translations
  expect_match(
    as.character(dbplyr::translate_sql(paste("a", "b"), con = con)),
    "concat",
    ignore.case = TRUE
  )

  DBI::dbDisconnect(con)
})

test_that("Aggregation function translations work with live connection", {
  drv <- DatabricksSQL()

  con <- DBI::dbConnect(drv, warehouse_id = test_warehouse_id_dbplyr)

  # Test aggregation translations
  expect_match(
    as.character(dbplyr::translate_sql(dplyr::n(), con = con, window = FALSE)),
    "count\\(\\*\\)",
    ignore.case = TRUE
  )
  expect_match(
    as.character(dbplyr::translate_sql(
      mean(x, na.rm = TRUE),
      con = con,
      window = FALSE
    )),
    "avg",
    ignore.case = TRUE
  )

  DBI::dbDisconnect(con)
})

test_that("Identifier escaping works with live connection", {
  drv <- DatabricksSQL()

  con <- DBI::dbConnect(drv, warehouse_id = test_warehouse_id_dbplyr)

  # Test identifier escaping
  escaped <- DBI::dbQuoteIdentifier(con, "my_table")
  expect_match(as.character(escaped), "`")
  expect_match(as.character(escaped), "my_table")

  DBI::dbDisconnect(con)
})

test_that("String escaping works with live connection", {
  drv <- DatabricksSQL()

  con <- DBI::dbConnect(drv, warehouse_id = test_warehouse_id_dbplyr)

  # Test string escaping
  escaped <- DBI::dbQuoteString(con, "test string")
  expect_match(as.character(escaped), "'")
  expect_match(as.character(escaped), "test string")

  DBI::dbDisconnect(con)
})

test_that("dbplyr dplyr::tbl() integration works", {
  drv <- DatabricksSQL()

  con <- DBI::dbConnect(drv, warehouse_id = test_warehouse_id_dbplyr)

  # Create a mock table reference using I() to prevent field discovery
  expect_no_error({
    tbl_ref <- dplyr::tbl(con, I("(SELECT 1 as test_col, 'hello' as test_str)"))
    expect_s3_class(tbl_ref, "tbl_dbi")
  })

  DBI::dbDisconnect(con)
})

test_that("Basic dplyr operations translate correctly", {
  drv <- DatabricksSQL()

  con <- DBI::dbConnect(drv, warehouse_id = test_warehouse_id_dbplyr)

  # Test basic dplyr operations without executing
  expect_no_error({
    # Test that dplyr operations can be chained without errors
    # Use dbplyr::sql() to create a query without field discovery
    tbl_ref <- dplyr::tbl(
      con,
      dbplyr::sql(
        "SELECT 'test_table' as table_name, 'BASE TABLE' as table_type, 'test_schema' as table_schema"
      )
    ) |>
      dplyr::filter(table_schema == "test_schema") |>
      dplyr::select(table_name, table_type) |>
      dplyr::arrange(table_name)

    # Test that the object was created successfully
    expect_s3_class(tbl_ref, "tbl_dbi")
  })

  DBI::dbDisconnect(con)
})

test_that("sql_query_save creates temporary views with live connection", {
  drv <- DatabricksSQL()

  con <- DBI::dbConnect(drv, warehouse_id = test_warehouse_id_dbplyr)

  # Test temporary view creation returns name
  temp_name <- dbplyr::sql_query_save(
    con,
    "SELECT 1 as test_col",
    "test_temp_view"
  )
  expect_type(temp_name, "character")
  expect_true(nzchar(temp_name))

  DBI::dbDisconnect(con)
})

test_that("Connection methods work as expected", {
  drv <- DatabricksSQL()

  con <- DBI::dbConnect(drv, warehouse_id = test_warehouse_id_dbplyr)

  # Test that connection is valid
  expect_true(DBI::dbIsValid(con))

  DBI::dbDisconnect(con)
})

test_that("Complex dbplyr translations work correctly", {
  drv <- DatabricksSQL()

  con <- DBI::dbConnect(drv, warehouse_id = test_warehouse_id_dbplyr)

  # Test window functions
  expect_match(
    as.character(dbplyr::translate_sql(
      dplyr::row_number(),
      con = con,
      window = TRUE
    )),
    "row_number",
    ignore.case = TRUE
  )
  expect_match(
    as.character(dbplyr::translate_sql(
      dplyr::min_rank(),
      con = con,
      window = TRUE
    )),
    "rank",
    ignore.case = TRUE
  )

  # Test mathematical functions
  expect_match(
    as.character(dbplyr::translate_sql(round(x), con = con)),
    "round",
    ignore.case = TRUE
  )
  expect_match(
    as.character(dbplyr::translate_sql(ceiling(x), con = con)),
    "ceil",
    ignore.case = TRUE
  )

  DBI::dbDisconnect(con)
})

test_that("dbQuoteIdentifier handles complex identifiers", {
  drv <- DatabricksSQL()

  con <- DBI::dbConnect(drv, warehouse_id = test_warehouse_id_dbplyr)

  # Test with Id object (schema.table)
  id_obj <- DBI::Id(
    catalog = "test_catalog",
    schema = "test_schema",
    table = "test_table"
  )
  escaped_id <- DBI::dbQuoteIdentifier(con, id_obj)
  expect_match(as.character(escaped_id), "`test_catalog`")
  expect_match(as.character(escaped_id), "`test_schema`")
  expect_match(as.character(escaped_id), "`test_table`")

  DBI::dbDisconnect(con)
})
