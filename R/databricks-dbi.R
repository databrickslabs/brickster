#' DBI Interface for Databricks SQL Warehouses
#'
#' @description
#' This file implements a standard DBI interface for Databricks SQL warehouses,
#' built on top of the existing `db_sql_query()` infrastructure.
#'
#' @importFrom methods new setClass setMethod
#' @importFrom cli cli_abort
#' @import DBI
#' @name databricks-dbi
NULL

# S4 Class Definitions --------------------------------------------------------

#' DBI Driver for Databricks
#' @export
setClass("DatabricksDriver", contains = "DBIDriver")

#' DBI Connection for Databricks
#' @export
setClass(
  "DatabricksConnection",
  contains = "DBIConnection",
  slots = list(
    warehouse_id = "character",
    host = "character",
    token = "character",
    catalog = "character",
    schema = "character"
  )
)

#' DBI Result for Databricks
#' @export
setClass(
  "DatabricksResult",
  contains = "DBIResult",
  slots = list(
    statement_id = "character",
    statement = "character",
    connection = "DatabricksConnection",
    completed = "logical",
    rows_fetched = "numeric"
  )
)

# Driver Methods ---------------------------------------------------------------

#' Create Databricks SQL Driver
#'
#' @return A DatabricksDriver object
#' @export
#' @examples
#' \dontrun{
#' drv <- DatabricksSQL()
#' con <- dbConnect(drv, warehouse_id = "your_warehouse_id")
#' }
DatabricksSQL <- function() {
  new("DatabricksDriver")
}


#' Show method for DatabricksDriver
#' @param object A DatabricksDriver object
#' @export
setMethod("show", "DatabricksDriver", function(object) {
  cat("<DatabricksDriver>\n")
})

# Connection Methods -----------------------------------------------------------

#' Connect to Databricks SQL Warehouse
#' 
#' @param drv A DatabricksDriver object
#' @param warehouse_id ID of the SQL warehouse to connect to
#' @param catalog Optional catalog name to use as default
#' @param schema Optional schema name to use as default
#' @param token Authentication token (defaults to db_token())
#' @param host Databricks workspace host (defaults to db_host())
#' @param ... Additional arguments (ignored)
#' @return A DatabricksConnection object
#' @export
setMethod(
  "dbConnect",
  "DatabricksDriver",
  function(
    drv,
    warehouse_id,
    catalog = NULL,
    schema = NULL,
    token = db_token(),
    host = db_host(),
    ...
  ) {
    # Validate required parameters
    if (
      missing(warehouse_id) || is.null(warehouse_id) || nchar(warehouse_id) == 0
    ) {
      cli::cli_abort("warehouse_id must be provided and non-empty")
    }

    # Validate connection by testing a simple query
    tryCatch(
      {
        test_result <- db_sql_query(
          warehouse_id = warehouse_id,
          statement = "SELECT 1 as test_connection",
          disposition = "INLINE",
          catalog = catalog,
          schema = schema,
          host = host,
          token = token
        )
      },
      error = function(e) {
        cli::cli_abort(
          "Failed to connect to warehouse {warehouse_id}: {e$message}"
        )
      }
    )

    # Create connection object
    new(
      "DatabricksConnection",
      warehouse_id = warehouse_id,
      host = host,
      token = token,
      catalog = if (is.null(catalog)) "" else catalog,
      schema = if (is.null(schema)) "" else schema
    )
  }
)

#' Disconnect from Databricks
#' @param conn A DatabricksConnection object
#' @param ... Additional arguments (ignored)
#' @return TRUE (invisibly)
#' @export
setMethod("dbDisconnect", "DatabricksConnection", function(conn, ...) {
  # Databricks connections are stateless, so just return TRUE
  invisible(TRUE)
})

#' Check if connection is valid
#' @param dbObj A DatabricksConnection object
#' @param ... Additional arguments (ignored)
#' @return TRUE if connection is valid, FALSE otherwise
#' @export
setMethod("dbIsValid", "DatabricksConnection", function(dbObj, ...) {
  # Check if connection has required fields
  !is.null(dbObj@warehouse_id) &&
    nchar(dbObj@warehouse_id) > 0 &&
    !is.null(dbObj@host) &&
    nchar(dbObj@host) > 0 &&
    !is.null(dbObj@token) &&
    nchar(dbObj@token) > 0
})

#' Show method for DatabricksConnection
#' @param object A DatabricksConnection object
#' @export
setMethod("show", "DatabricksConnection", function(object) {
  cat("<DatabricksConnection>\n")
  cat("  Warehouse ID:", object@warehouse_id, "\n")
  cat("  Host:", object@host, "\n")
  if (nchar(object@catalog) > 0) {
    cat("  Catalog:", object@catalog, "\n")
  }
  if (nchar(object@schema) > 0) {
    cat("  Schema:", object@schema, "\n")
  }
})

# Query Methods ----------------------------------------------------------------

#' Send query to Databricks (asynchronous)
#' @param conn A DatabricksConnection object
#' @param statement SQL statement to execute
#' @param ... Additional arguments (ignored)
#' @return A DatabricksResult object
#' @export
setMethod(
  "dbSendQuery",
  signature = c(conn = "DatabricksConnection", statement = "character"),
  function(conn, statement, ...) {
    # Validate inputs
    if (!dbIsValid(conn)) {
      cli::cli_abort("Connection is not valid")
    }

    if (
      missing(statement) || is.null(statement) || nchar(trimws(statement)) == 0
    ) {
      cli::cli_abort("statement must be provided and non-empty")
    }

    # Execute query asynchronously
    resp <- db_sql_exec_query(
      warehouse_id = conn@warehouse_id,
      statement = statement,
      catalog = if (nchar(conn@catalog) > 0) conn@catalog else NULL,
      schema = if (nchar(conn@schema) > 0) conn@schema else NULL,
      disposition = "EXTERNAL_LINKS",
      format = "ARROW_STREAM",
      wait_timeout = "0s", # Async execution
      host = conn@host,
      token = conn@token
    )

    # Create result object
    new(
      "DatabricksResult",
      statement_id = resp$statement_id,
      statement = statement,
      connection = conn,
      completed = FALSE,
      rows_fetched = 0
    )
  }
)

#' Execute SQL query and return results
#'
#' @param conn A DatabricksConnection object
#' @param statement SQL statement to execute
#' @param disposition Query disposition mode: "EXTERNAL_LINKS" (default) for large results,
#'   "INLINE" for small metadata queries (automatically chooses appropriate format)
#' @param ... Additional arguments passed to underlying query execution
#' @return A data.frame with query results
#' @export
setMethod(
  "dbGetQuery",
  signature = c(conn = "DatabricksConnection", statement = "character"),
  function(conn, statement, disposition = "EXTERNAL_LINKS", ...) {
    # Use unified db_sql_query function
    db_sql_query(
      warehouse_id = conn@warehouse_id,
      statement = statement,
      catalog = if (nchar(conn@catalog) > 0) conn@catalog else NULL,
      schema = if (nchar(conn@schema) > 0) conn@schema else NULL,
      return_arrow = FALSE,
      disposition = disposition,
      host = conn@host,
      token = conn@token
    )
  }
)

# Read-only enforcement
#' Send statement to Databricks (not supported)
#' @param conn A DatabricksConnection object
#' @param statement SQL statement
#' @param ... Additional arguments (ignored)
#' @return Always throws an error (read-only connection)
#' @export
setMethod(
  "dbSendStatement",
  signature = c(conn = "DatabricksConnection", statement = "character"),
  function(conn, statement, ...) {
    cli::cli_abort(
      "This is a read-only connection. Use dbSendQuery() for SELECT statements only."
    )
  }
)

#' Execute statement on Databricks (not supported)
#' @param conn A DatabricksConnection object
#' @param statement SQL statement
#' @param ... Additional arguments (ignored)
#' @return Always throws an error (read-only connection)
#' @export
setMethod(
  "dbExecute",
  signature = c(conn = "DatabricksConnection", statement = "character"),
  function(conn, statement, ...) {
    cli::cli_abort(
      "This is a read-only connection. Use dbGetQuery() for SELECT statements only."
    )
  }
)

# Result Methods ---------------------------------------------------------------

#' Fetch results from Databricks query
#' @param res A DatabricksResult object
#' @param n Maximum number of rows to fetch (-1 for all rows)
#' @param ... Additional arguments (ignored)
#' @return A data.frame with query results
#' @export
setMethod("dbFetch", "DatabricksResult", function(res, n = -1, ...) {
  if (res@completed) {
    # Return empty data frame if already completed
    return(data.frame())
  }

  # Get current status (poll if needed)
  status <- db_sql_exec_status(
    statement_id = res@statement_id,
    host = res@connection@host,
    token = res@connection@token
  )

  if (status$status$state %in% c("RUNNING", "PENDING")) {
    status <- db_sql_exec_poll_for_success(res@statement_id)
  }

  if (status$status$state == "FAILED") {
    cli::cli_abort("Query failed: {status$status$error$message}")
  }

  # Check for empty results early and return immediately
  # Use total_row_count to detect empty result sets
  if (status$manifest$total_row_count == 0) {
    results <- db_sql_create_empty_result(status$manifest)
  } else {
    # Use helper function to fetch results (no more duplicated logic!)
    results <- db_sql_fetch_results(
      statement_id = res@statement_id,
      manifest = status$manifest,
      return_arrow = FALSE,
      max_active_connections = 30,
      row_limit = if (n > 0) n else NULL,
      host = res@connection@host,
      token = res@connection@token
    )
  }

  # Mark as completed and update rows fetched
  res@completed <- TRUE
  res@rows_fetched <- nrow(results)

  results
})

#' Check if query has completed
#' @param res A DatabricksResult object
#' @param ... Additional arguments (ignored)
#' @return TRUE if query is complete, FALSE otherwise
#' @export
setMethod("dbHasCompleted", "DatabricksResult", function(res, ...) {
  if (res@completed) {
    return(TRUE)
  }

  # Check current status
  status <- db_sql_exec_status(
    statement_id = res@statement_id,
    host = res@connection@host,
    token = res@connection@token
  )

  status$status$state %in% c("SUCCEEDED", "FAILED", "CANCELED", "CLOSED")
})

#' Clear result set
#' @param res A DatabricksResult object
#' @param ... Additional arguments (ignored)
#' @return TRUE (invisibly)
#' @export
setMethod("dbClearResult", "DatabricksResult", function(res, ...) {
  # Databricks automatically cleans up after a period of time
  # Mark as completed to prevent reuse
  res@completed <- TRUE
  invisible(TRUE)
})

#' Get SQL statement from result
#' @param res A DatabricksResult object
#' @param ... Additional arguments (ignored)
#' @return The SQL statement as character
#' @export
setMethod("dbGetStatement", "DatabricksResult", function(res, ...) {
  res@statement
})

#' Get number of rows fetched
#' @param res A DatabricksResult object
#' @param ... Additional arguments (ignored)
#' @return Number of rows fetched so far
#' @export
setMethod("dbGetRowCount", "DatabricksResult", function(res, ...) {
  res@rows_fetched
})

#' Get number of rows affected (not applicable for SELECT)
#' @param res A DatabricksResult object
#' @param ... Additional arguments (ignored)
#' @return -1 (not applicable for SELECT queries)
#' @export
setMethod("dbGetRowsAffected", "DatabricksResult", function(res, ...) {
  # For SELECT queries, return -1 (no rows affected)
  -1
})

#' Get column information from result
#' @param res A DatabricksResult object
#' @param ... Additional arguments (ignored)
#' @return A data.frame with column names and types
#' @export
setMethod("dbColumnInfo", "DatabricksResult", function(res, ...) {
  # Get column info from the result metadata
  status <- db_sql_exec_status(
    statement_id = res@statement_id,
    host = res@connection@host,
    token = res@connection@token
  )

  if (status$status$state == "SUCCEEDED" && !is.null(status$manifest$schema)) {
    schema <- status$manifest$schema
    tibble::tibble(
      name = purrr::map_chr(schema$columns, "name"),
      type = purrr::map_chr(schema$columns, "type_name")
    )
  } else {
    tibble::tibble(name = character(0), type = character(0))
  }
})

#' Show method for DatabricksResult
#' @param object A DatabricksResult object
#' @export
setMethod("show", "DatabricksResult", function(object) {
  cat("<DatabricksResult>\n")
  cat(
    "  Statement:",
    substr(object@statement, 1, 50),
    if (nchar(object@statement) > 50) "..." else "",
    "\n"
  )
  cat("  Statement ID:", object@statement_id, "\n")
  cat("  Completed:", object@completed, "\n")
  cat("  Rows fetched:", object@rows_fetched, "\n")
})

# Table and Database Metadata Methods -----------------------------------------

#' List tables in Databricks catalog/schema
#' @param conn A DatabricksConnection object
#' @param ... Additional arguments (ignored)
#' @return Character vector of table names
#' @export
setMethod("dbListTables", "DatabricksConnection", function(conn, ...) {
  if (!dbIsValid(conn)) {
    cli::cli_abort("Connection is not valid")
  }

  # Use SQL query approach (standard for DBI drivers)
  sql <- if (nchar(conn@catalog) > 0 && nchar(conn@schema) > 0) {
    paste0("SHOW TABLES IN ", conn@catalog, ".", conn@schema)
  } else if (nchar(conn@schema) > 0) {
    paste0("SHOW TABLES IN ", conn@schema)
  } else {
    "SHOW TABLES"
  }

  result <- dbGetQuery(conn, sql, disposition = "INLINE")

  # Extract table names from result
  if ("tableName" %in% names(result)) {
    result$tableName
  } else if ("table_name" %in% names(result)) {
    result$table_name
  } else {
    # Fallback to first column
    result[[1]]
  }
})

#' Check if table exists in Databricks
#' @param conn A DatabricksConnection object
#' @param name Table name to check
#' @param ... Additional arguments (ignored)
#' @return TRUE if table exists, FALSE otherwise
#' @export
setMethod(
  "dbExistsTable",
  signature = c(conn = "DatabricksConnection", name = "character"),
  function(conn, name, ...) {
    if (!dbIsValid(conn)) {
      cli::cli_abort("Connection is not valid")
    }

    # Clean table name - remove quotes if present
    clean_name <- gsub('^\"|\"$', '', name)

    # Use DESCRIBE TABLE to check existence
    tryCatch(
      {
        sql <- paste0("DESCRIBE TABLE ", clean_name)
        dbGetQuery(conn, sql, disposition = "INLINE")
        TRUE
      },
      error = function(e) {
        FALSE
      }
    )
  }
)

#' Get connection information
#' @param dbObj A DatabricksConnection object
#' @param ... Additional arguments (ignored)
#' @return A list with connection details
#' @export
setMethod("dbGetInfo", "DatabricksConnection", function(dbObj, ...) {
  list(
    db.version = "Databricks SQL",
    dbname = paste0(
      dbObj@catalog,
      if (nchar(dbObj@catalog) > 0 && nchar(dbObj@schema) > 0) "." else "",
      dbObj@schema
    ),
    username = NA_character_,
    host = dbObj@host,
    port = NA_integer_,
    warehouse_id = dbObj@warehouse_id
  )
})

#' List column names of a Databricks table
#' @param conn A DatabricksConnection object
#' @param name Table name to describe
#' @param ... Additional arguments (ignored)
#' @return Character vector of column names
#' @export
setMethod(
  "dbListFields",
  signature = c(conn = "DatabricksConnection", name = "character"),
  function(conn, name, ...) {
    if (!dbIsValid(conn)) {
      cli::cli_abort("Connection is not valid")
    }

    # Clean table name - remove quotes if present
    clean_name <- gsub('^"|"$', '', name)

    # Use DESCRIBE TABLE to get column information with inline disposition
    sql <- paste0("DESCRIBE TABLE ", clean_name)
    result <- db_sql_query(
      warehouse_id = conn@warehouse_id,
      statement = sql,
      catalog = if (nchar(conn@catalog) > 0) conn@catalog else NULL,
      schema = if (nchar(conn@schema) > 0) conn@schema else NULL,
      return_arrow = FALSE,
      disposition = "INLINE",
      host = conn@host,
      token = conn@token
    )

    # Extract column names
    if ("col_name" %in% names(result)) {
      result$col_name
    } else if ("column_name" %in% names(result)) {
      result$column_name
    } else {
      # Fallback to first column
      result[[1]]
    }
  }
)

# Read-only transaction methods (for completeness)
#' Begin transaction (not supported)
#' @param conn A DatabricksConnection object
#' @param ... Additional arguments (ignored)
#' @return Always throws an error (read-only connection)
#' @export
setMethod("dbBegin", "DatabricksConnection", function(conn, ...) {
  cli::cli_abort("Transactions are not supported in this read-only interface")
})

#' Commit transaction (not supported)
#' @param conn A DatabricksConnection object
#' @param ... Additional arguments (ignored)
#' @return Always throws an error (read-only connection)
#' @export
setMethod("dbCommit", "DatabricksConnection", function(conn, ...) {
  cli::cli_abort("Transactions are not supported in this read-only interface")
})

#' Rollback transaction (not supported)
#' @param conn A DatabricksConnection object
#' @param ... Additional arguments (ignored)
#' @return Always throws an error (read-only connection)
#' @export
setMethod("dbRollback", "DatabricksConnection", function(conn, ...) {
  cli::cli_abort("Transactions are not supported in this read-only interface")
})

# Additional utility methods
#' Check if connection is read-only
#' @param dbObj A DatabricksConnection object
#' @param ... Additional arguments (ignored)
#' @return TRUE (always read-only for Databricks connections)
#' @export
setMethod("dbIsReadOnly", "DatabricksConnection", function(dbObj, ...) {
  TRUE
})

#' Map R data types to Databricks SQL types
#' @param dbObj A DatabricksConnection object
#' @param obj R object(s) to get SQL types for
#' @param ... Additional arguments (ignored)
#' @return Character vector of SQL type names
#' @export
setMethod("dbDataType", "DatabricksConnection", function(dbObj, obj, ...) {
  # Map R types to Databricks SQL types
  purrr::map_chr(
    obj,
    function(x) {
      switch(
        class(x)[1],
        logical = "BOOLEAN",
        integer = "INT",
        numeric = "DOUBLE",
        character = "STRING",
        Date = "DATE",
        POSIXct = "TIMESTAMP",
        "STRING"
      )
    }
  )
})

# Identifier Quoting Methods ----------------------------------------------------

#' Quote identifiers for Databricks SQL
#' @param conn A DatabricksConnection object
#' @param x Character vector of identifiers to quote
#' @param ... Additional arguments (ignored)
#' @return SQL object with quoted identifiers
#' @export
setMethod(
  "dbQuoteIdentifier",
  signature("DatabricksConnection", "character"),
  function(conn, x, ...) {
    # Simple identifiers - wrap in backticks
    quoted <- paste0("`", x, "`")
    DBI::SQL(quoted)
  }
)

#' Quote SQL objects (passthrough)
#' @param conn A DatabricksConnection object
#' @param x SQL object (already quoted)
#' @param ... Additional arguments (ignored)
#' @return The SQL object unchanged
#' @export
setMethod(
  "dbQuoteIdentifier",
  signature("DatabricksConnection", "SQL"),
  function(conn, x, ...) {
    # SQL objects are already quoted
    x
  }
)

#' Quote complex identifiers (schema.table)
#' @param conn A DatabricksConnection object
#' @param x Id object with catalog/schema/table components
#' @param ... Additional arguments (ignored)
#' @return SQL object with quoted identifier components
#' @export
setMethod(
  "dbQuoteIdentifier",
  signature("DatabricksConnection", "Id"),
  function(conn, x, ...) {
    # Handle schema.table identifiers
    names <- purrr::map_chr(x@name, ~ paste0("`", .x, "`"))
    DBI::SQL(paste(names, collapse = "."))
  }
)
