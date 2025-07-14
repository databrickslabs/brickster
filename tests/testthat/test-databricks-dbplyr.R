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
    schema = ""
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
    schema = ""
  )

  # Test basic string translations without executing
  expect_true(grepl(
    "concat",
    as.character(dbplyr::translate_sql(paste("a", "b"), con = con)),
    ignore.case = TRUE
  ))
})

test_that("Aggregation function translations work offline", {
  con <- new(
    "DatabricksConnection",
    warehouse_id = "test_warehouse",
    host = "test_host",
    token = "test_token",
    catalog = "",
    schema = ""
  )

  # Test aggregation translations without executing
  expect_true(grepl(
    "count\\(\\*\\)",
    as.character(dbplyr::translate_sql(dplyr::n(), con = con, window = FALSE)),
    ignore.case = TRUE
  ))
  expect_true(grepl(
    "avg",
    as.character(dbplyr::translate_sql(
      mean(x, na.rm = TRUE),
      con = con,
      window = FALSE
    )),
    ignore.case = TRUE
  ))
})

test_that("Identifier escaping uses backticks", {
  con <- new(
    "DatabricksConnection",
    warehouse_id = "test_warehouse",
    host = "test_host",
    token = "test_token",
    catalog = "",
    schema = ""
  )

  # Test identifier escaping
  escaped <- DBI::dbQuoteIdentifier(con, "my_table")
  expect_true(grepl("`", as.character(escaped)))
  expect_true(grepl("my_table", as.character(escaped)))

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
    schema = ""
  )

  # Test string escaping
  escaped <- DBI::dbQuoteString(con, "test string")
  expect_true(grepl("'", as.character(escaped)))
  expect_true(grepl("test string", as.character(escaped)))
})

test_that("Read-only table operations are blocked offline", {
  con <- new(
    "DatabricksConnection",
    warehouse_id = "test_warehouse",
    host = "test_host",
    token = "test_token",
    catalog = "",
    schema = ""
  )

  expect_error(
    dbplyr::sql_query_save(con, "SELECT 1", "temp_table"),
    "not supported in read-only mode"
  )
})

test_that("SQL table analyze generates correct SQL", {
  con <- new(
    "DatabricksConnection",
    warehouse_id = "test_warehouse",
    host = "test_host",
    token = "test_token",
    catalog = "",
    schema = ""
  )

  sql <- dbplyr::sql_table_analyze(con, "test_table")
  expect_true(grepl("ANALYZE TABLE", as.character(sql)))
  expect_true(grepl("test_table", as.character(sql)))
  expect_true(grepl("COMPUTE STATISTICS", as.character(sql)))
})

# Online Tests (require warehouse connection) --------------------------------

test_that("dbplyr edition is correctly declared with live connection", {
  drv <- DatabricksSQL()
  warehouse_id <- Sys.getenv("DATABRICKS_WAREHOUSE_ID")
  skip_if(nchar(warehouse_id) == 0, "No DATABRICKS_WAREHOUSE_ID available")

  con <- DBI::dbConnect(drv, warehouse_id = warehouse_id)
  edition <- dbplyr::dbplyr_edition(con)
  expect_equal(edition, 2L)

  DBI::dbDisconnect(con)
})

test_that("String function translations work with live connection", {
  drv <- DatabricksSQL()
  warehouse_id <- Sys.getenv("DATABRICKS_WAREHOUSE_ID")
  skip_if(nchar(warehouse_id) == 0, "No DATABRICKS_WAREHOUSE_ID available")

  con <- DBI::dbConnect(drv, warehouse_id = warehouse_id)

  # Test basic string translations
  expect_true(grepl(
    "concat",
    as.character(dbplyr::translate_sql(paste("a", "b"), con = con)),
    ignore.case = TRUE
  ))

  DBI::dbDisconnect(con)
})

test_that("Aggregation function translations work with live connection", {
  drv <- DatabricksSQL()
  warehouse_id <- Sys.getenv("DATABRICKS_WAREHOUSE_ID")
  skip_if(nchar(warehouse_id) == 0, "No DATABRICKS_WAREHOUSE_ID available")

  con <- DBI::dbConnect(drv, warehouse_id = warehouse_id)

  # Test aggregation translations
  expect_true(grepl(
    "count\\(\\*\\)",
    as.character(dbplyr::translate_sql(dplyr::n(), con = con, window = FALSE)),
    ignore.case = TRUE
  ))
  expect_true(grepl(
    "avg",
    as.character(dbplyr::translate_sql(
      mean(x, na.rm = TRUE),
      con = con,
      window = FALSE
    )),
    ignore.case = TRUE
  ))

  DBI::dbDisconnect(con)
})

test_that("Identifier escaping works with live connection", {
  drv <- DatabricksSQL()
  warehouse_id <- Sys.getenv("DATABRICKS_WAREHOUSE_ID")
  skip_if(nchar(warehouse_id) == 0, "No DATABRICKS_WAREHOUSE_ID available")

  con <- DBI::dbConnect(drv, warehouse_id = warehouse_id)

  # Test identifier escaping
  escaped <- DBI::dbQuoteIdentifier(con, "my_table")
  expect_true(grepl("`", as.character(escaped)))
  expect_true(grepl("my_table", as.character(escaped)))

  DBI::dbDisconnect(con)
})

test_that("String escaping works with live connection", {
  drv <- DatabricksSQL()
  warehouse_id <- Sys.getenv("DATABRICKS_WAREHOUSE_ID")
  skip_if(nchar(warehouse_id) == 0, "No DATABRICKS_WAREHOUSE_ID available")

  con <- DBI::dbConnect(drv, warehouse_id = warehouse_id)

  # Test string escaping
  escaped <- DBI::dbQuoteString(con, "test string")
  expect_true(grepl("'", as.character(escaped)))
  expect_true(grepl("test string", as.character(escaped)))

  DBI::dbDisconnect(con)
})

test_that("dbplyr dplyr::tbl() integration works", {
  drv <- DatabricksSQL()
  warehouse_id <- Sys.getenv("DATABRICKS_WAREHOUSE_ID")
  skip_if(nchar(warehouse_id) == 0, "No DATABRICKS_WAREHOUSE_ID available")

  con <- DBI::dbConnect(drv, warehouse_id = warehouse_id)

  # Create a mock table reference using I() to prevent field discovery
  expect_no_error({
    tbl_ref <- dplyr::tbl(con, I("(SELECT 1 as test_col, 'hello' as test_str)"))
    expect_s3_class(tbl_ref, "tbl_dbi")
  })

  DBI::dbDisconnect(con)
})

test_that("Basic dplyr operations translate correctly", {
  drv <- DatabricksSQL()
  warehouse_id <- Sys.getenv("DATABRICKS_WAREHOUSE_ID")
  skip_if(nchar(warehouse_id) == 0, "No DATABRICKS_WAREHOUSE_ID available")

  con <- DBI::dbConnect(drv, warehouse_id = warehouse_id)

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

test_that("Read-only restrictions are enforced with live connection", {
  drv <- DatabricksSQL()
  warehouse_id <- Sys.getenv("DATABRICKS_WAREHOUSE_ID")
  skip_if(nchar(warehouse_id) == 0, "No DATABRICKS_WAREHOUSE_ID available")

  con <- DBI::dbConnect(drv, warehouse_id = warehouse_id)

  # Test that temporary table creation is blocked
  expect_error(
    dbplyr::sql_query_save(con, "SELECT 1", "temp_table"),
    "not supported in read-only mode"
  )

  DBI::dbDisconnect(con)
})

test_that("Connection methods work as expected", {
  drv <- DatabricksSQL()
  warehouse_id <- Sys.getenv("DATABRICKS_WAREHOUSE_ID")
  skip_if(nchar(warehouse_id) == 0, "No DATABRICKS_WAREHOUSE_ID available")

  con <- DBI::dbConnect(drv, warehouse_id = warehouse_id)

  # Test that connection is valid
  expect_true(DBI::dbIsValid(con))

  DBI::dbDisconnect(con)
})

test_that("Complex dbplyr translations work correctly", {
  drv <- DatabricksSQL()
  warehouse_id <- Sys.getenv("DATABRICKS_WAREHOUSE_ID")
  skip_if(nchar(warehouse_id) == 0, "No DATABRICKS_WAREHOUSE_ID available")

  con <- DBI::dbConnect(drv, warehouse_id = warehouse_id)

  # Test window functions
  expect_true(grepl(
    "row_number",
    as.character(dbplyr::translate_sql(
      dplyr::row_number(),
      con = con,
      window = TRUE
    )),
    ignore.case = TRUE
  ))
  expect_true(grepl(
    "rank",
    as.character(dbplyr::translate_sql(
      dplyr::min_rank(),
      con = con,
      window = TRUE
    )),
    ignore.case = TRUE
  ))

  # Test mathematical functions
  expect_true(grepl(
    "round",
    as.character(dbplyr::translate_sql(round(x), con = con)),
    ignore.case = TRUE
  ))
  expect_true(grepl(
    "ceil",
    as.character(dbplyr::translate_sql(ceiling(x), con = con)),
    ignore.case = TRUE
  ))

  DBI::dbDisconnect(con)
})

test_that("dbQuoteIdentifier handles complex identifiers", {
  drv <- DatabricksSQL()
  warehouse_id <- Sys.getenv("DATABRICKS_WAREHOUSE_ID")
  skip_if(nchar(warehouse_id) == 0, "No DATABRICKS_WAREHOUSE_ID available")

  con <- DBI::dbConnect(drv, warehouse_id = warehouse_id)

  # Test with Id object (schema.table)
  id_obj <- DBI::Id(
    catalog = "test_catalog",
    schema = "test_schema",
    table = "test_table"
  )
  escaped_id <- DBI::dbQuoteIdentifier(con, id_obj)
  expect_true(grepl("`test_catalog`", as.character(escaped_id)))
  expect_true(grepl("`test_schema`", as.character(escaped_id)))
  expect_true(grepl("`test_table`", as.character(escaped_id)))

  DBI::dbDisconnect(con)
})
