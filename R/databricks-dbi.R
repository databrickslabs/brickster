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
    schema = "character",
    staging_volume = "character"
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
#' @param staging_volume Optional volume path for large dataset staging
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
    staging_volume = NULL,
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
          token = token,
          show_progress = FALSE
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
      schema = if (is.null(schema)) "" else schema,
      staging_volume = if (is.null(staging_volume)) "" else staging_volume
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
  if (!is.null(object@staging_volume) && nchar(object@staging_volume) > 0) {
    cat("  Staging Volume:", object@staging_volume, "\n")
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
#' @param show_progress If TRUE, show progress updates during query execution (default: TRUE)
#' @param ... Additional arguments passed to underlying query execution
#' @return A data.frame with query results
#' @export
setMethod(
  "dbGetQuery",
  signature = c(conn = "DatabricksConnection", statement = "character"),
  function(conn, statement, disposition = "EXTERNAL_LINKS", show_progress = TRUE, ...) {
    # Use unified db_sql_query function
    db_sql_query(
      warehouse_id = conn@warehouse_id,
      statement = statement,
      catalog = if (nchar(conn@catalog) > 0) conn@catalog else NULL,
      schema = if (nchar(conn@schema) > 0) conn@schema else NULL,
      return_arrow = FALSE,
      disposition = disposition,
      host = conn@host,
      token = conn@token,
      show_progress = show_progress
    )
  }
)

# Read-only enforcement
#' Send statement to Databricks
#' @param conn A DatabricksConnection object
#' @param statement SQL statement
#' @param ... Additional arguments (ignored)
#' @return A DatabricksResult object
#' @export
setMethod(
  "dbSendStatement",
  signature = c(conn = "DatabricksConnection", statement = "character"),
  function(conn, statement, ...) {
    # Validate inputs
    if (
      missing(statement) || is.null(statement) || nchar(trimws(statement)) == 0
    ) {
      cli::cli_abort("statement must be provided and non-empty")
    }

    # Execute statement asynchronously
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

#' Execute statement on Databricks
#' @param conn A DatabricksConnection object
#' @param statement SQL statement
#' @param ... Additional arguments (ignored)
#' @return Number of rows in result set (from metadata, without loading data)
#' @export
setMethod(
  "dbExecute",
  signature = c(conn = "DatabricksConnection", statement = "character"),
  function(conn, statement, ...) {
    # Validate inputs
    if (
      missing(statement) || is.null(statement) || nchar(trimws(statement)) == 0
    ) {
      cli::cli_abort("statement must be provided and non-empty")
    }

    # Execute statement synchronously to get metadata without loading data
    status <- db_sql_exec_and_wait(
      warehouse_id = conn@warehouse_id,
      statement = statement,
      catalog = if (nchar(conn@catalog) > 0) conn@catalog else NULL,
      schema = if (nchar(conn@schema) > 0) conn@schema else NULL,
      disposition = "EXTERNAL_LINKS",
      format = "ARROW_STREAM",
      wait_timeout = "10s",
      host = conn@host,
      token = conn@token,
      show_progress = FALSE # No progress for metadata queries
    )

    # Return row count from manifest without loading data
    # For DDL statements, total_row_count may be 0 or NULL
    if (
      !is.null(status$manifest) && !is.null(status$manifest$total_row_count)
    ) {
      as.integer(status$manifest$total_row_count)
    } else {
      0L
    }
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

  # Poll for completion (handles status checking internally)
  status <- db_sql_exec_poll_for_success(res@statement_id)

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

  result <- dbGetQuery(conn, sql, disposition = "INLINE", show_progress = FALSE)

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
        dbGetQuery(conn, sql, disposition = "INLINE", show_progress = FALSE)
        TRUE
      },
      error = function(e) {
        FALSE
      }
    )
  }
)

#' Check if table exists (Id method)
#' @param conn A DatabricksConnection object
#' @param name Table name as Id object
#' @param ... Additional arguments (ignored)
#' @return TRUE if table exists, FALSE otherwise
#' @export
setMethod(
  "dbExistsTable",
  signature = c(conn = "DatabricksConnection", name = "Id"),
  function(conn, name, ...) {
    if (!dbIsValid(conn)) {
      cli::cli_abort("Connection is not valid")
    }

    # Convert Id to quoted string
    quoted_name <- dbQuoteIdentifier(conn, name)

    # Use DESCRIBE TABLE to check existence
    tryCatch(
      {
        sql <- paste0("DESCRIBE TABLE ", quoted_name)
        dbGetQuery(conn, sql, disposition = "INLINE", show_progress = FALSE)
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

# Transaction methods (not supported)
#' Begin transaction (not supported)
#' @param conn A DatabricksConnection object
#' @param ... Additional arguments (ignored)
#' @return Always throws an error (transactions not supported)
#' @export
setMethod("dbBegin", "DatabricksConnection", function(conn, ...) {
  cli::cli_abort("Transactions are not supported")
})

#' Commit transaction (not supported)
#' @param conn A DatabricksConnection object
#' @param ... Additional arguments (ignored)
#' @return Always throws an error (transactions not supported)
#' @export
setMethod("dbCommit", "DatabricksConnection", function(conn, ...) {
  cli::cli_abort("Transactions are not supported")
})

#' Rollback transaction (not supported)
#' @param conn A DatabricksConnection object
#' @param ... Additional arguments (ignored)
#' @return Always throws an error (transactions not supported)
#' @export
setMethod("dbRollback", "DatabricksConnection", function(conn, ...) {
  cli::cli_abort("Transactions are not supported")
})

# Additional utility methods

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
    # Handle each element of the character vector
    quoted <- purrr::map_chr(x, function(single_x) {
      # Check if this is a three-part name (catalog.schema.table)
      if (grepl("^[^.]+\\.[^.]+\\.[^.]+$", single_x)) {
        # Split into parts and quote each separately
        parts <- strsplit(single_x, "\\.")[[1]]
        if (length(parts) == 3) {
          quoted_parts <- paste0("`", parts, "`")
          paste(quoted_parts, collapse = ".")
        } else {
          # Fallback to simple quoting
          paste0("`", single_x, "`")
        }
      } else {
        # Simple identifiers - wrap in backticks
        paste0("`", single_x, "`")
      }
    })
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

# Write Methods ----------------------------------------------------------------

#' Write a data frame to Databricks table
#' @param conn A DatabricksConnection object
#' @param name Table name (character, Id, or SQL)
#' @param value Data frame to write
#' @param overwrite If TRUE, overwrite existing table
#' @param append If TRUE, append to existing table
#' @param row.names If TRUE, preserve row names as a column
#' @param temporary If TRUE, create temporary table (NOT SUPPORTED - will error)
#' @param field.types Named character vector of SQL types for columns
#' @param staging_volume Optional volume path for large dataset staging
#' @param progress If TRUE, show progress bar for file uploads (default: TRUE)
#' @param ... Additional arguments
#' @return TRUE invisibly on success
#' @export
setMethod(
  "dbWriteTable",
  signature = c("DatabricksConnection", "character", "data.frame"),
  function(
    conn,
    name,
    value,
    overwrite = FALSE,
    append = FALSE,
    row.names = FALSE,
    temporary = FALSE,
    field.types = NULL,
    staging_volume = NULL,
    progress = TRUE,
    ...
  ) {
    # Validate inputs
    if (overwrite && append) {
      cli::cli_abort("Cannot specify both overwrite = TRUE and append = TRUE")
    }

    if (temporary) {
      cli::cli_abort(
        "Temporary tables are not supported with the SQL Statement Execution API"
      )
    }

    if (nrow(value) == 0) {
      cli::cli_abort("Cannot write empty data frame")
    }

    # Handle row names
    if (row.names) {
      if (".row_names" %in% names(value)) {
        cli::cli_abort(
          "Cannot preserve row names: column '.row_names' already exists"
        )
      }
      value <- tibble::add_column(
        value,
        .row_names = rownames(value),
        .before = 1
      )
    }

    # Quote table name
    quoted_name <- dbQuoteIdentifier(conn, name)

    # Use staging_volume from connection if not provided
    if (!is.null(staging_volume)) {
      effective_staging_volume <- staging_volume
    } else if (nchar(conn@staging_volume) > 0) {
      effective_staging_volume <- conn@staging_volume
    } else {
      effective_staging_volume <- NULL
    }

    # Handle table existence checks for both methods
    table_exists <- dbExistsTable(conn, name)

    if (table_exists && !overwrite && !append) {
      cli::cli_abort(
        "Table {quoted_name} already exists. Use overwrite = TRUE or append = TRUE"
      )
    }

    if (append && !table_exists) {
      cli::cli_abort(
        "Table {quoted_name} does not exist. Cannot append to non-existing table."
      )
    }

    # Check if we should use volume-based method
    if (
      db_should_use_volume_method(value, effective_staging_volume, temporary)
    ) {
      db_write_table_volume(
        conn,
        quoted_name,
        value,
        effective_staging_volume,
        append,
        progress
      )
    } else {
      db_write_table_standard(
        conn,
        quoted_name,
        value,
        overwrite,
        append,
        field.types,
        temporary
      )
    }

    invisible(TRUE)
  }
)

#' Write a data frame to Databricks table (Id method)
#' @param conn A DatabricksConnection object
#' @param name Table name as Id object
#' @param value Data frame to write
#' @param overwrite If TRUE, overwrite existing table
#' @param append If TRUE, append to existing table
#' @param row.names If TRUE, preserve row names as a column
#' @param temporary If TRUE, create temporary table (NOT SUPPORTED - will error)
#' @param field.types Named character vector of SQL types for columns
#' @param staging_volume Optional volume path for large dataset staging
#' @param progress If TRUE, show progress bar for file uploads (default: TRUE)
#' @param ... Additional arguments
#' @return TRUE invisibly on success
#' @export
setMethod(
  "dbWriteTable",
  signature = c("DatabricksConnection", "Id", "data.frame"),
  function(
    conn,
    name,
    value,
    overwrite = FALSE,
    append = FALSE,
    row.names = FALSE,
    temporary = FALSE,
    field.types = NULL,
    staging_volume = NULL,
    progress = TRUE,
    ...
  ) {
    # Handle Id object by implementing the logic directly instead of delegating
    # This avoids double-quoting issues

    # Validate inputs
    if (overwrite && append) {
      cli::cli_abort("Cannot specify both overwrite = TRUE and append = TRUE")
    }

    if (temporary) {
      cli::cli_abort(
        "Temporary tables are not supported with the SQL Statement Execution API"
      )
    }

    if (nrow(value) == 0) {
      cli::cli_abort("Cannot write empty data frame")
    }

    # Handle row names if requested
    if (row.names) {
      value <- tibble::add_column(
        value,
        row_names = rownames(value),
        .before = 1
      )
    }

    # Get proper quoted name for Id object
    quoted_name <- dbQuoteIdentifier(conn, name)

    # Determine staging volume to use
    effective_staging_volume <- staging_volume
    if (is.null(effective_staging_volume) && nchar(conn@staging_volume) > 0) {
      effective_staging_volume <- conn@staging_volume
    }

    # Check if table exists for overwrite/append logic
    table_exists <- dbExistsTable(conn, name)
    if (table_exists && !overwrite && !append) {
      cli::cli_abort(
        "Table {quoted_name} already exists. Use overwrite = TRUE or append = TRUE"
      )
    }

    if (append && !table_exists) {
      cli::cli_abort(
        "Table {quoted_name} does not exist. Cannot append to non-existing table."
      )
    }

    # Check if we should use volume-based method
    if (
      db_should_use_volume_method(value, effective_staging_volume, temporary)
    ) {
      db_write_table_volume(
        conn,
        quoted_name,
        value,
        effective_staging_volume,
        append,
        progress
      )
    } else {
      db_write_table_standard(
        conn,
        quoted_name,
        value,
        overwrite,
        append,
        field.types,
        temporary
      )
    }

    invisible(TRUE)
  }
)

#' Write table to Databricks (AsIs name signature)
#' @param conn DatabricksConnection object
#' @param name Table name as AsIs object (from I())
#' @param value Data frame to write
#' @param overwrite If TRUE, overwrite existing table
#' @param append If TRUE, append to existing table
#' @param row.names If TRUE, preserve row names as a column
#' @param temporary If TRUE, create temporary table (NOT SUPPORTED - will error)
#' @param field.types Named character vector of SQL types for columns
#' @param staging_volume Optional volume path for large dataset staging
#' @param progress If TRUE, show progress bar for file uploads (default: TRUE)
#' @param ... Additional arguments
#' @return TRUE invisibly on success
#' @export
setMethod(
  "dbWriteTable",
  signature = c("DatabricksConnection", "AsIs", "data.frame"),
  function(
    conn,
    name,
    value,
    overwrite = FALSE,
    append = FALSE,
    row.names = FALSE,
    temporary = FALSE,
    field.types = NULL,
    staging_volume = NULL,
    progress = TRUE,
    ...
  ) {
    # Convert AsIs to character and delegate to character method
    char_name <- as.character(name)
    dbWriteTable(
      conn = conn,
      name = char_name,
      value = value,
      overwrite = overwrite,
      append = append,
      row.names = row.names,
      temporary = temporary,
      field.types = field.types,
      staging_volume = staging_volume,
      progress = progress,
      ...
    )
  }
)

#' Write table using standard SQL approach
#' @keywords internal
db_write_table_standard <- function(
  conn,
  quoted_name,
  value,
  overwrite,
  append,
  field.types,
  temporary = FALSE
) {
  if (temporary) {
    cli::cli_abort(
      "Temporary tables are not supported with the SQL Statement Execution API"
    )
  }
  
  # Show progress for table creation
  cli::cli_progress_step(
    if (append) "Appending data to table" else "Creating table",
    if (append) "Data appended" else "Table created"
  )
  
  if (append) {
    # For append, use atomic INSERT INTO with SELECT VALUES
    if (nrow(value) > 0) {
      db_append_with_select_values(conn, quoted_name, value)
    }
  } else {
    # For create/overwrite, use atomic CTAS with VALUES
    db_create_table_as_select_values(
      conn,
      quoted_name,
      value,
      field.types,
      temporary,
      overwrite
    )
  }
  
  cli::cli_progress_done()
}

#' Create table from data frame structure
#' @keywords internal
db_create_table_from_data <- function(
  conn,
  quoted_name,
  value,
  field.types,
  temporary = FALSE,
  overwrite = FALSE
) {
  if (temporary) {
    cli::cli_abort(
      "Temporary tables are not supported with the SQL Statement Execution API"
    )
  }
  # Generate column definitions
  if (is.null(field.types)) {
    # Use automatic type mapping for each column
    col_types <- purrr::map_chr(value, function(col) {
      switch(
        class(col)[1],
        logical = "BOOLEAN",
        integer = "INT",
        numeric = "DOUBLE",
        character = "STRING",
        Date = "DATE",
        POSIXct = "TIMESTAMP",
        "STRING"
      )
    })
  } else {
    # Use provided types
    col_types <- field.types[names(value)]
    # Fill missing types with automatic mapping
    missing_types <- is.na(col_types) |
      names(value) %in% names(field.types) == FALSE
    col_types[missing_types] <- purrr::map_chr(
      value[missing_types],
      function(col) {
        switch(
          class(col)[1],
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
  }

  # Build column definitions
  col_names <- purrr::map_chr(names(value), ~ dbQuoteIdentifier(conn, .x))
  col_defs <- paste(col_names, col_types, collapse = ", ")

  # Create table
  if (temporary) {
    table_keyword <- "CREATE TEMPORARY TABLE"
  } else if (overwrite) {
    table_keyword <- "CREATE OR REPLACE TABLE"
  } else {
    table_keyword <- "CREATE TABLE"
  }
  create_sql <- paste0(table_keyword, " ", quoted_name, " (", col_defs, ")")
  dbExecute(conn, create_sql)
}


#' Generate VALUES SQL from data frame
#' @keywords internal
db_generate_values_sql <- function(conn, data) {
  # Convert each row to SQL values
  row_values <- apply(data, 1, function(row) {
    values <- purrr::map_chr(row, function(val) {
      if (is.na(val)) {
        "NULL"
      } else if (is.character(val)) {
        paste0("'", gsub("'", "''", val), "'") # Escape single quotes
      } else if (is.logical(val)) {
        if (val) "TRUE" else "FALSE"
      } else {
        as.character(val)
      }
    })
    paste0("(", paste(values, collapse = ", "), ")")
  })

  paste(row_values, collapse = ", ")
}

#' Generate type-aware VALUES SQL from data frame
#' @keywords internal
db_generate_typed_values_sql <- function(conn, data) {
  # Convert each row to SQL values with proper typing
  row_values <- apply(data, 1, function(row) {
    values <- purrr::map2_chr(row, names(data), function(val, col_name) {
      col_data <- data[[col_name]]

      if (is.na(val)) {
        "NULL"
      } else if (is.logical(col_data)) {
        if (as.logical(val)) "TRUE" else "FALSE"
      } else if (is.numeric(col_data)) {
        # Don't quote numeric values to preserve type
        as.character(val)
      } else if (is.character(col_data)) {
        # Quote string values and escape single quotes
        paste0("'", gsub("'", "''", val), "'")
      } else {
        # Default to quoted string for other types
        paste0("'", gsub("'", "''", as.character(val)), "'")
      }
    })
    paste0("(", paste(values, collapse = ", "), ")")
  })

  paste(row_values, collapse = ", ")
}

#' Create table using atomic CTAS with VALUES
#' @keywords internal
db_create_table_as_select_values <- function(
  conn,
  quoted_name,
  value,
  field.types,
  temporary = FALSE,
  overwrite = FALSE
) {
  if (temporary) {
    cli::cli_abort(
      "Temporary tables are not supported with the SQL Statement Execution API"
    )
  }
  if (nrow(value) == 0) {
    # For empty data, fall back to CREATE TABLE with schema
    db_create_table_from_data(
      conn,
      quoted_name,
      value,
      field.types,
      temporary,
      overwrite
    )
    return()
  }

  # Build table creation keywords
  if (temporary) {
    table_keyword <- "CREATE TEMPORARY TABLE"
  } else if (overwrite) {
    table_keyword <- "CREATE OR REPLACE TABLE"
  } else {
    table_keyword <- "CREATE TABLE"
  }

  # Get column names with proper quoting
  col_names <- purrr::map_chr(names(value), ~ dbQuoteIdentifier(conn, .x))
  col_list <- paste(col_names, collapse = ", ")

  # Generate VALUES clause with type-aware formatting
  values_sql <- db_generate_typed_values_sql(conn, value)

  # Build complete CTAS statement
  ctas_sql <- paste0(
    table_keyword,
    " ",
    quoted_name,
    " AS SELECT * FROM VALUES ",
    values_sql,
    " AS t(",
    col_list,
    ")"
  )

  # Execute using helper function
  db_sql_exec_and_wait(
    warehouse_id = conn@warehouse_id,
    statement = ctas_sql,
    catalog = if (nchar(conn@catalog) > 0) conn@catalog else NULL,
    schema = if (nchar(conn@schema) > 0) conn@schema else NULL,
    disposition = "INLINE",
    format = "JSON_ARRAY",
    wait_timeout = "10s",
    host = conn@host,
    token = conn@token,
    show_progress = FALSE
  )
}

#' Append data using atomic INSERT INTO with SELECT VALUES
#' @keywords internal
db_append_with_select_values <- function(conn, quoted_name, value) {
  # Get column names with proper quoting
  col_names <- purrr::map_chr(names(value), ~ dbQuoteIdentifier(conn, .x))
  col_list <- paste(col_names, collapse = ", ")

  # Generate VALUES clause with type-aware formatting
  values_sql <- db_generate_typed_values_sql(conn, value)

  # Build atomic INSERT statement
  insert_sql <- paste0(
    "INSERT INTO ",
    quoted_name,
    " SELECT * FROM VALUES ",
    values_sql,
    " AS t(",
    col_list,
    ")"
  )

  # Execute using helper function
  db_sql_exec_and_wait(
    warehouse_id = conn@warehouse_id,
    statement = insert_sql,
    catalog = if (nchar(conn@catalog) > 0) conn@catalog else NULL,
    schema = if (nchar(conn@schema) > 0) conn@schema else NULL,
    disposition = "INLINE",
    format = "JSON_ARRAY",
    wait_timeout = "10s",
    host = conn@host,
    token = conn@token,
    show_progress = FALSE
  )
}

#' Check if volume method should be used
#' @keywords internal
db_should_use_volume_method <- function(
  value,
  staging_volume,
  temporary = FALSE
) {
  n_rows <- nrow(value)
  has_volume <- !is.null(staging_volume) && nchar(staging_volume) > 0

  # Temporary tables should use standard method (COPY INTO may not support them)
  if (temporary) {
    return(FALSE)
  }

  # Check if arrow is available
  has_arrow <- rlang::is_installed("arrow")

  # Check dataset size limits without volume staging
  if (!has_volume) {
    if (n_rows > 50000) {
      # Fail for very large datasets
      cli::cli_abort(c(
        "Cannot write {n_rows} rows without volume staging.",
        "x" = "Standard SQL method is not suitable for datasets larger than 30,000 rows.",
        "i" = "Use the {.arg staging_volume} parameter to enable volume-based uploads.",
        "i" = "Example: {.code dbWriteTable(conn, name, data, staging_volume = '/Volumes/catalog/schema/volume')}"
      ))
    } else if (n_rows >= 20000 && has_arrow) {
      # Warn about performance for medium-large datasets
      cli::cli_warn(c(
        "Writing {n_rows} rows using standard SQL method will be slow.",
        "i" = "Consider using {.arg staging_volume} parameter for better performance.",
        "i" = "Example: {.code dbWriteTable(conn, name, data, staging_volume = '/Volumes/catalog/schema/volume')}"
      ))
    }
  }

  has_volume && n_rows > 20000 && has_arrow
}

#' Write table using volume-based approach
#' @keywords internal
db_write_table_volume <- function(
  conn,
  quoted_name,
  value,
  staging_volume,
  append = FALSE,
  progress = TRUE
) {
  # Validate volume path
  staging_volume <- is_valid_volume_path(staging_volume)

  if (
    !db_volume_dir_exists(staging_volume, host = conn@host, token = conn@token)
  ) {
    cli::cli_abort("Staging volume directory does not exist: {staging_volume}")
  }

  # Generate unique directory name for dataset
  temp_dirname <- paste0(
    "brickster_upload_",
    format(Sys.time(), "%Y%m%d_%H%M%S"),
    "_",
    sample(10000:99999, 1)
  )

  volume_dataset_path <- file.path(staging_volume, temp_dirname)
  local_temp_dir <- file.path(tempdir(), temp_dirname)

  # Set up cleanup hooks to ensure cleanup happens even if there are errors
  on.exit(
    {
      # Cleanup local directory
      if (dir.exists(local_temp_dir)) {
        unlink(local_temp_dir, recursive = TRUE)
      }

      # Clean up volume directory (recursive since it contains files)
      # Use tryCatch to avoid errors during cleanup from stopping the exit handler
      tryCatch(
        {
          db_volume_dir_delete(
            volume_dataset_path,
            recursive = TRUE,
            host = conn@host,
            token = conn@token
          )
        },
        error = function(e) {
          # Log cleanup failure but don't stop execution
          cli::cli_warn(
            "Failed to clean up volume directory {volume_dataset_path}: {e$message}"
          )
        }
      )
    },
    add = TRUE
  )

  # Convert to Parquet
  if (progress) {
    cli::cli_progress_step(
      "Converting to Parquet format",
      "Parquet files created"
    )
  }

  arrow::write_dataset(
    value,
    local_temp_dir,
    format = "parquet",
    compression = "zstd",
    max_rows_per_file = 5000000L
  )

  if (progress) {
    cli::cli_progress_done()
  }

  # Create staging directory
  db_volume_dir_create(
    volume_dataset_path,
    host = conn@host,
    token = conn@token
  )

  # Upload files to volume
  db_volume_upload_dir(
    local_dir = local_temp_dir,
    volume_dir = volume_dataset_path,
    overwrite = TRUE,
    preserve_structure = TRUE,
    host = conn@host,
    token = conn@token
  )

  # Execute SQL to create/populate table
  if (progress) {
    cli::cli_progress_step(
      if (append) "Appending data to table" else "Creating table from uploaded data",
      if (append) "Data appended" else "Table created"
    )
  }

  # Execute SQL based on operation type
  if (append) {
    # Append to existing table
    copy_sql <- paste0(
      "COPY INTO ",
      quoted_name,
      " ",
      "FROM '",
      volume_dataset_path,
      "' ",
      "FILEFORMAT = PARQUET"
    )
  } else {
    # Create new table from parquet files using READ_FILES
    copy_sql <- paste0(
      "CREATE OR REPLACE TABLE ",
      quoted_name,
      " AS SELECT * FROM READ_FILES('",
      volume_dataset_path,
      "', format => 'parquet')"
    )
  }

  # Execute SQL using helper function (inline since we don't need data back)
  db_sql_exec_and_wait(
    warehouse_id = conn@warehouse_id,
    statement = copy_sql,
    catalog = if (nchar(conn@catalog) > 0) conn@catalog else NULL,
    schema = if (nchar(conn@schema) > 0) conn@schema else NULL,
    disposition = "INLINE",
    format = "JSON_ARRAY",
    wait_timeout = "10s",
    host = conn@host,
    token = conn@token,
    show_progress = FALSE
  )

  if (progress) cli::cli_progress_done()
}

#' Append rows to an existing Databricks table
#' @param conn A DatabricksConnection object
#' @param name Table name (character, Id, or SQL)
#' @param value Data frame to append
#' @param ... Additional arguments
#' @param row.names If TRUE, preserve row names as a column
#' @return TRUE invisibly on success
#' @export
setMethod(
  "dbAppendTable",
  signature = c("DatabricksConnection", "character", "data.frame"),
  function(conn, name, value, ..., row.names = FALSE) {
    # Validate inputs
    if (nrow(value) == 0) {
      cli::cli_abort("Cannot append empty data frame")
    }

    # Check table exists
    if (!dbExistsTable(conn, name)) {
      cli::cli_abort(
        "Table {name} does not exist. Use dbWriteTable() to create it first."
      )
    }

    # Use dbWriteTable with append = TRUE
    dbWriteTable(conn, name, value, append = TRUE, row.names = row.names, ...)
  }
)

#' Append rows to an existing Databricks table (Id method)
#' @param conn A DatabricksConnection object
#' @param name Table name as Id object
#' @param value Data frame to append
#' @param ... Additional arguments
#' @param row.names If TRUE, preserve row names as a column
#' @return TRUE invisibly on success
#' @export
setMethod(
  "dbAppendTable",
  signature = c("DatabricksConnection", "Id", "data.frame"),
  function(conn, name, value, ..., row.names = FALSE) {
    # Validate inputs
    if (nrow(value) == 0) {
      cli::cli_abort("Cannot append empty data frame")
    }

    # Check table exists
    if (!dbExistsTable(conn, name)) {
      table_name <- as.character(dbQuoteIdentifier(conn, name))
      cli::cli_abort(
        "Table {table_name} does not exist. Use dbWriteTable() to create it first."
      )
    }

    # Use dbWriteTable with append = TRUE
    dbWriteTable(conn, name, value, append = TRUE, row.names = row.names, ...)
  }
)
