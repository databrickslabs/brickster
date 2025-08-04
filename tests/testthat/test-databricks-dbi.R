# Load required packages
library(brickster)

# Offline Tests (no warehouse connection required) ---------------------------

test_that("DatabricksSQL driver can be created", {
  drv <- DatabricksSQL()
  expect_s4_class(drv, "DatabricksDriver")
  expect_true(is(drv, "DBIDriver"))
})

test_that("DatabricksSQL driver show method works", {
  drv <- DatabricksSQL()
  expect_output(show(drv), "<DatabricksDriver>")
})

test_that("Connection parameter validation works offline", {
  drv <- DatabricksSQL()

  # Test missing warehouse_id
  expect_error(dbConnect(drv), "warehouse_id must be provided")
  expect_error(
    dbConnect(drv, warehouse_id = ""),
    "warehouse_id must be provided"
  )
  expect_error(
    dbConnect(drv, warehouse_id = NULL),
    "warehouse_id must be provided"
  )

  # Test with invalid credentials (should fail at connection test)
  expect_error(
    dbConnect(
      drv,
      warehouse_id = "fake_id",
      host = "fake_host",
      token = "fake_token"
    ),
    "Failed to connect"
  )
})

test_that("DatabricksConnection validation methods work", {
  # Create a connection object manually for testing (not through dbConnect)
  con <- new(
    "DatabricksConnection",
    warehouse_id = "test_warehouse",
    host = "test_host",
    token = "test_token",
    catalog = "test_catalog",
    schema = "test_schema",
    staging_volume = ""
  )

  expect_true(dbIsValid(con))

  # Test show method
  expect_output(show(con), "<DatabricksConnection>")
  expect_output(show(con), "test_warehouse")
  expect_output(show(con), "test_catalog")
  expect_output(show(con), "test_schema")

  # Test info method
  info <- dbGetInfo(con)
  expect_type(info, "list")
  expect_equal(info$warehouse_id, "test_warehouse")
  expect_equal(info$db.version, "Databricks SQL")
  expect_equal(info$host, "test_host")
})

test_that("DatabricksConnection with invalid parameters fails validation", {
  # Empty warehouse_id
  con_invalid <- new(
    "DatabricksConnection",
    warehouse_id = "",
    host = "test_host",
    token = "test_token",
    catalog = "",
    schema = "",
    staging_volume = ""
  )
  expect_false(dbIsValid(con_invalid))
})

test_that("Data type mapping works correctly", {
  con <- new(
    "DatabricksConnection",
    warehouse_id = "test_warehouse",
    host = "test_host",
    token = "test_token",
    catalog = "",
    schema = "",
    staging_volume = ""
  )

  test_data <- list(
    logical = TRUE,
    integer = 1L,
    numeric = 1.5,
    character = "test",
    Date = Sys.Date(),
    POSIXct = Sys.time()
  )

  types <- dbDataType(con, test_data)
  expect_equal(unname(types["logical"]), "BOOLEAN")
  expect_equal(unname(types["integer"]), "INT")
  expect_equal(unname(types["numeric"]), "DOUBLE")
  expect_equal(unname(types["character"]), "STRING")
  expect_equal(unname(types["Date"]), "DATE")
  expect_equal(unname(types["POSIXct"]), "TIMESTAMP")
})

test_that("Transaction restrictions work offline", {
  con <- new(
    "DatabricksConnection",
    warehouse_id = "test_warehouse",
    host = "test_host",
    token = "test_token",
    catalog = "",
    schema = "",
    staging_volume = ""
  )

  # Transactions are not supported
  expect_error(dbBegin(con), "not supported")
  expect_error(dbCommit(con), "not supported")
  expect_error(dbRollback(con), "not supported")
})

test_that("Quote handling utility functions work", {
  clean_quoted <- function(name) gsub('^"|"$', '', name)

  expect_equal(clean_quoted("table_name"), "table_name")
  expect_equal(clean_quoted('"table_name"'), "table_name")
  expect_equal(clean_quoted('catalog.schema.table'), "catalog.schema.table")
  expect_equal(clean_quoted('"catalog.schema.table"'), "catalog.schema.table")
  expect_equal(clean_quoted('samples.nyctaxi.trips'), "samples.nyctaxi.trips")
  expect_equal(clean_quoted('"samples.nyctaxi.trips"'), "samples.nyctaxi.trips")
})

test_that("DatabricksResult show method works", {
  # Create a result object for testing
  res <- new(
    "DatabricksResult",
    statement_id = "test_statement_id",
    statement = "SELECT 1 as test_column",
    connection = new(
      "DatabricksConnection",
      warehouse_id = "test_warehouse",
      host = "test_host",
      token = "test_token",
      catalog = "",
      schema = "",
      staging_volume = ""
    ),
    completed = FALSE,
    rows_fetched = 0
  )

  expect_output(show(res), "<DatabricksResult>")
  expect_output(show(res), "test_statement_id")
  expect_output(show(res), "SELECT 1")
})

test_that("DatabricksConnection with empty catalog/schema works", {
  con <- new(
    "DatabricksConnection",
    warehouse_id = "test_warehouse",
    host = "test_host",
    token = "test_token",
    catalog = "",
    schema = "",
    staging_volume = ""
  )

  info <- dbGetInfo(con)
  expect_equal(info$dbname, "")
})

test_that("DatabricksConnection with catalog only works", {
  con <- new(
    "DatabricksConnection",
    warehouse_id = "test_warehouse",
    host = "test_host",
    token = "test_token",
    catalog = "test_catalog",
    schema = "",
    staging_volume = ""
  )

  info <- dbGetInfo(con)
  expect_equal(info$dbname, "test_catalog")
})

test_that("DatabricksResult edge cases work offline", {
  res <- new(
    "DatabricksResult",
    statement_id = "test_id",
    statement = "SELECT 1",
    connection = new(
      "DatabricksConnection",
      warehouse_id = "test_warehouse",
      host = "test_host",
      token = "test_token",
      catalog = "",
      schema = "",
      staging_volume = ""
    ),
    completed = TRUE,
    rows_fetched = 5
  )

  # Test that completed results return expected values
  expect_equal(dbGetRowCount(res), 5)
  expect_equal(dbGetRowsAffected(res), -1)
  expect_true(dbHasCompleted(res))

  # Fetch on completed result should return empty data frame
  empty_result <- dbFetch(res)
  expect_s3_class(empty_result, "data.frame")
  expect_equal(nrow(empty_result), 0)
})

# Online Tests (require warehouse connection) --------------------------------

skip_on_cran()
skip_unless_authenticated()

# Set up test warehouse for all DBI tests
test_warehouse_id <- tryCatch(
  {
    create_test_warehouse()
  },
  error = function(e) {
    # Return NULL if warehouse creation fails
    NULL
  }
)

# Skip all tests if warehouse creation failed
skip_if(is.null(test_warehouse_id), "Could not create test warehouse")

# Set up cleanup on exit (only if warehouse was created successfully)
withr::defer(
  {
    cleanup_test_warehouse(test_warehouse_id)
  },
  testthat::teardown_env()
)

test_that("DBI connection can be created with valid warehouse_id", {
  drv <- DatabricksSQL()

  con <- dbConnect(drv, warehouse_id = test_warehouse_id)
  expect_s4_class(con, "DatabricksConnection")
  expect_true(is(con, "DBIConnection"))
  expect_true(dbIsValid(con))

  # Clean up
  dbDisconnect(con)
})

test_that("DBI connection info is correct", {
  drv <- DatabricksSQL()

  con <- dbConnect(drv, warehouse_id = test_warehouse_id)
  info <- dbGetInfo(con)

  expect_type(info, "list")
  expect_equal(info$warehouse_id, test_warehouse_id)
  expect_equal(info$db.version, "Databricks SQL")
  expect_true(is.character(info$host))

  dbDisconnect(con)
})

test_that("Transaction operations are not supported", {
  drv <- DatabricksSQL()

  con <- dbConnect(drv, warehouse_id = test_warehouse_id)

  # Only transactions are not supported, DDL/DML should work
  expect_error(dbBegin(con), "not supported")
  expect_error(dbCommit(con), "not supported")
  expect_error(dbRollback(con), "not supported")

  # SQL statements should work (test with a safe operation that won't leave artifacts)
  expect_no_error({
    result <- dbGetQuery(con, "SELECT 1 as test_col", show_progress = FALSE)
    expect_equal(result$test_col, 1)
  })

  dbDisconnect(con)
})

test_that("dbGetQuery works for simple queries", {
  drv <- DatabricksSQL()

  con <- dbConnect(drv, warehouse_id = test_warehouse_id)

  # Test simple query
  result <- dbGetQuery(con, "SELECT 1 as test_col", show_progress = FALSE)
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1)
  expect_equal(result$test_col, 1)

  # Test more complex query
  result <- dbGetQuery(
    con,
    "SELECT 1 as a, 'test' as b, 3.14 as c",
    show_progress = FALSE
  )
  expect_equal(nrow(result), 1)
  expect_equal(ncol(result), 3)
  expect_equal(result$a, 1)
  expect_equal(result$b, "test")
  expect_equal(result$c, 3.14)

  dbDisconnect(con)
})

test_that("dbSendQuery and dbFetch work correctly", {
  drv <- DatabricksSQL()

  con <- dbConnect(drv, warehouse_id = test_warehouse_id)

  # Test async query execution
  res <- dbSendQuery(con, "SELECT 1 as test_col")
  expect_s4_class(res, "DatabricksResult")
  expect_true(is(res, "DBIResult"))

  # Initially not completed (async)
  expect_false(res@completed)

  # Fetch results
  result <- dbFetch(res)
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1)
  expect_equal(result$test_col, 1)

  # Should be completed after fetch
  expect_true(dbHasCompleted(res))
  # Note: dbGetRowCount may not be updated until after completion
  expect_true(dbGetRowCount(res) >= 0) # At least ensure it's not negative
  expect_equal(dbGetStatement(res), "SELECT 1 as test_col")

  # Clean up
  dbClearResult(res)
  dbDisconnect(con)
})

test_that("dbColumnInfo works", {
  drv <- DatabricksSQL()

  con <- dbConnect(drv, warehouse_id = test_warehouse_id)

  res <- dbSendQuery(con, "SELECT 1 as test_int, 'hello' as test_string")

  # Fetch to complete the query
  data <- dbFetch(res)

  # Get column info
  col_info <- dbColumnInfo(res)
  expect_s3_class(col_info, "data.frame")
  expect_true("name" %in% names(col_info))
  expect_true("type" %in% names(col_info))

  dbClearResult(res)
  dbDisconnect(con)
})

test_that("Table listing functions work", {
  drv <- DatabricksSQL()

  con <- dbConnect(drv, warehouse_id = test_warehouse_id)

  # Test dbListTables (may be empty but should not error)
  tables <- dbListTables(con)
  expect_true(is.character(tables) || length(tables) == 0)

  dbDisconnect(con)
})

test_that("Connection with catalog and schema works", {
  drv <- DatabricksSQL()
  catalog <- "system"
  schema <- "information_schema"

  con <- dbConnect(
    drv,
    warehouse_id = test_warehouse_id,
    catalog = catalog,
    schema = schema
  )
  expect_equal(con@catalog, catalog)
  expect_equal(con@schema, schema)

  # Test query in specific catalog/schema context
  result <- dbGetQuery(con, "SELECT 1 as test", show_progress = FALSE)
  expect_equal(result$test, 1)

  dbDisconnect(con)
})

test_that("Error handling works correctly", {
  drv <- DatabricksSQL()

  con <- dbConnect(drv, warehouse_id = test_warehouse_id)

  # Test invalid SQL - expect any error containing "PARSE_SYNTAX_ERROR" or "Query failed"
  expect_error(
    dbGetQuery(con, "INVALID SQL STATEMENT", show_progress = FALSE),
    "(Query failed|PARSE_SYNTAX_ERROR)"
  )

  # Test empty statement
  expect_error(dbSendQuery(con, ""), "statement must be provided")
  expect_error(dbSendQuery(con, "   "), "statement must be provided")

  dbDisconnect(con)
})

test_that("dbDataType works correctly with live connection", {
  drv <- DatabricksSQL()

  con <- dbConnect(drv, warehouse_id = test_warehouse_id)

  # Test type mapping
  test_data <- list(
    logical = TRUE,
    integer = 1L,
    numeric = 1.5,
    character = "test",
    Date = Sys.Date(),
    POSIXct = Sys.time()
  )

  types <- dbDataType(con, test_data)
  expect_equal(unname(types["logical"]), "BOOLEAN")
  expect_equal(unname(types["integer"]), "INT")
  expect_equal(unname(types["numeric"]), "DOUBLE")
  expect_equal(unname(types["character"]), "STRING")
  expect_equal(unname(types["Date"]), "DATE")
  expect_equal(unname(types["POSIXct"]), "TIMESTAMP")

  dbDisconnect(con)
})

test_that("dbExistsTable works correctly", {
  drv <- DatabricksSQL()

  con <- dbConnect(drv, warehouse_id = test_warehouse_id)

  # Test with a table that should not exist
  expect_false(dbExistsTable(con, "non_existent_table_12345"))

  # Test with quoted table name
  expect_false(dbExistsTable(con, '"non_existent_table_12345"'))

  dbDisconnect(con)
})

test_that("dbListFields handles errors gracefully", {
  drv <- DatabricksSQL()

  con <- dbConnect(drv, warehouse_id = test_warehouse_id)

  # Test with non-existent table should error
  expect_error(dbListFields(con, "non_existent_table_12345"))

  dbDisconnect(con)
})

test_that("DatabricksResult methods work with empty results", {
  drv <- DatabricksSQL()

  con <- dbConnect(drv, warehouse_id = test_warehouse_id)

  # Test with query that returns no rows
  res <- dbSendQuery(con, "SELECT 1 as test WHERE 1 = 0")

  # Should still work even with no results
  expect_s4_class(res, "DatabricksResult")
  expect_equal(dbGetStatement(res), "SELECT 1 as test WHERE 1 = 0")
  expect_equal(dbGetRowsAffected(res), -1)

  # Fetch should return empty data frame
  result <- dbFetch(res)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0)

  dbClearResult(res)
  dbDisconnect(con)
})

# Field Discovery Tests ------------------------------------------------------

test_that("Field discovery works with information_schema tables", {
  drv <- DatabricksSQL()

  con <- dbConnect(drv, warehouse_id = test_warehouse_id)

  # Test field discovery on information_schema.tables
  expect_no_error({
    fields <- dbListFields(con, "information_schema.tables")
    expect_true(is.character(fields))
    expect_true(length(fields) > 0)
    expect_true("table_name" %in% tolower(fields) || "tableName" %in% fields)
  })

  dbDisconnect(con)
})

test_that("Field discovery query returns correct structure", {
  drv <- DatabricksSQL()

  con <- dbConnect(drv, warehouse_id = test_warehouse_id)

  # Test that field discovery query (WHERE 0 = 1) returns empty result with correct structure
  result <- dbGetQuery(
    con,
    "SELECT 'test' as col1, 1 as col2, current_date() as col3 WHERE 0 = 1",
    disposition = "INLINE",
    show_progress = FALSE
  )

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0) # Should have no rows
  expect_equal(ncol(result), 3) # Should have 3 columns
  expect_equal(names(result), c("col1", "col2", "col3"))

  dbDisconnect(con)
})

test_that("dbplyr field discovery integration works", {
  drv <- DatabricksSQL()

  con <- dbConnect(drv, warehouse_id = test_warehouse_id)

  # Test that dbplyr can discover fields for SQL queries
  expect_no_error({
    # This should trigger field discovery internally
    tbl_ref <- dplyr::tbl(
      con,
      dplyr::sql("SELECT 1 as test_col, 'hello' as test_str")
    )

    # Accessing colnames should work
    cols <- colnames(tbl_ref)
    expect_true("test_col" %in% cols)
    expect_true("test_str" %in% cols)
  })

  dbDisconnect(con)
})


test_that("Volume method selection logic works correctly", {
  # Test data of different sizes
  small_data <- data.frame(x = 1:100, y = letters[1:100])
  medium_data <- data.frame(x = 1:15000, y = rep(letters, 15000 / 26)[1:15000])
  large_data <- data.frame(x = 1:25000, y = rep(letters, 25000 / 26)[1:25000])

  # Test without volume (should always return FALSE)
  expect_false(db_should_use_volume_method(small_data, NULL))
  expect_false(db_should_use_volume_method(medium_data, NULL))

  # Test with volume but small data (should return FALSE)
  expect_false(db_should_use_volume_method(
    small_data,
    "/Volumes/test/test/test"
  ))

  # Test with volume but medium data (should return FALSE as threshold is > 20000)
  expect_false(db_should_use_volume_method(
    medium_data,
    "/Volumes/test/test/test"
  ))

  # Test temporary table (should always return FALSE regardless of size/volume)
  expect_false(db_should_use_volume_method(
    large_data,
    "/Volumes/test/test/test",
    temporary = TRUE
  ))

  # Test large data with volume (should depend on arrow availability)
  skip_if(!rlang::is_installed("arrow"), "arrow package not available")
  expect_true(db_should_use_volume_method(
    large_data,
    "/Volumes/test/test/test"
  ))
})

test_that("dbAppendTable method signatures work correctly offline", {
  # Create mock connection object
  con <- new(
    "DatabricksConnection",
    warehouse_id = "test_warehouse",
    host = "test_host",
    token = "test_token",
    catalog = "",
    schema = "",
    staging_volume = ""
  )

  # Test data
  test_data <- data.frame(x = 1:3, y = c("a", "b", "c"))

  # Test that method exists for character table names
  expect_true(hasMethod(
    "dbAppendTable",
    c("DatabricksConnection", "character", "data.frame")
  ))

  # Test that method exists for Id table names
  expect_true(hasMethod(
    "dbAppendTable",
    c("DatabricksConnection", "Id", "data.frame")
  ))

  # Test with character name (will fail due to connection, but method should exist)
  expect_error(
    dbAppendTable(con, "test_table", test_data),
    "Failed to connect|does not exist"
  )

  # Test with Id name (will fail due to connection, but method should exist)
  id_name <- DBI::Id(catalog = "test", schema = "default", table = "test_table")
  expect_error(
    dbAppendTable(con, id_name, test_data),
    "Failed to connect|does not exist"
  )
})
