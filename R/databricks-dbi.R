#' DBI Interface for Databricks SQL Warehouses
#'
#' @description
#' This file implements a standard DBI interface for Databricks SQL warehouses,
#' built on top of the existing `db_sql_query()` infrastructure.
#'
#' @importFrom methods new setClass setMethod
#' @import DBI
#' @name databricks-dbi
NULL

# S4 Class Definitions --------------------------------------------------------
setClassUnion("characterOrNULL", c("character", "NULL"))

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
    token = "characterOrNULL",
    catalog = "character",
    schema = "character",
    staging_volume = "character",
    disposition = "character",
    max_active_connections = "numeric",
    fetch_timeout = "numeric",
    show_progress = "logical",
    state = "environment"
  ),
  prototype = list(show_progress = TRUE)
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
    rows_fetched = "numeric",
    state = "environment"
  ),
  prototype = list(completed = FALSE, rows_fetched = 0)
)

setMethod("initialize", "DatabricksConnection", function(.Object, ...) {
  .Object <- methods::callNextMethod()
  .Object@state <- new.env(parent = emptyenv())
  .Object@state$closed <- FALSE
  .Object@state$results <- new.env(parent = emptyenv())
  .Object
})

setMethod("initialize", "DatabricksResult", function(.Object, ...) {
  .Object <- methods::callNextMethod()
  state <- new.env(parent = emptyenv())
  state$closed <- FALSE
  state$kind <- "query"
  state$completed <- isTRUE(.Object@completed)
  state$rows_fetched <- .Object@rows_fetched
  state$statement_id <- .Object@statement_id
  state$status <- NULL
  state$buffer <- NULL
  state$buffer_pos <- 0
  state$next_chunk_index <- 0L
  state$loaded_rows <- 0
  state$seen <- integer()
  state$ptype <- data.frame()
  .Object@state <- state
  if (length(.Object@statement_id) == 1L && nzchar(.Object@statement_id)) {
    .Object@connection@state$results[[.Object@statement_id]] <- state
  }
  .Object
})

# Driver Methods ---------------------------------------------------------------

#' Create Databricks SQL Driver
#'
#' @returns A DatabricksDriver object
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
#' @details Provide either `warehouse_id` or `http_path`. When `http_path` is
#'   supplied, the warehouse ID is extracted from the `/warehouses/<id>` segment.
#' @param drv A DatabricksDriver object
#' @param warehouse_id Optional ID of the SQL warehouse to connect to
#' @param http_path Optional HTTP path for the SQL warehouse; if provided,
#'   the warehouse ID is extracted from this path
#' @param catalog Optional catalog name to use as default
#' @param schema Optional schema name to use as default
#' @param staging_volume Optional volume path for large dataset staging
#' @param disposition Query disposition mode to use by default for DBI query
#'   results. Use `"EXTERNAL_LINKS"` for large results or `"INLINE"` for
#'   smaller results that must avoid direct cloud-storage result downloads.
#' @param max_active_connections Maximum number of concurrent download
#' connections when fetching query results (default: 30)
#' @param fetch_timeout Timeout in seconds for downloading each result chunk
#' (default: 300)
#' @param show_progress If `TRUE`, show progress updates by default for DBI
#'   queries, dbplyr collection, and table writes (default: `TRUE`)
#' @param token Authentication token (defaults to db_token())
#' @param host Databricks workspace host (defaults to db_host())
#' @param ... Additional arguments (ignored)
#' @returns A DatabricksConnection object
#' @export
setMethod(
  "dbConnect",
  "DatabricksDriver",
  function(
    drv,
    warehouse_id = NULL,
    http_path = NULL,
    catalog = NULL,
    schema = NULL,
    staging_volume = NULL,
    disposition = c("EXTERNAL_LINKS", "INLINE"),
    max_active_connections = 30,
    fetch_timeout = 300,
    show_progress = TRUE,
    token = db_token(),
    host = db_host(),
    ...
  ) {
    disposition <- match.arg(disposition)

    # Validate required parameters
    if (
      !is.null(warehouse_id) &&
        nzchar(warehouse_id) &&
        !is.null(http_path) &&
        nzchar(http_path)
    ) {
      cli::cli_abort("Specify only one of {.arg warehouse_id} or {.arg http_path}")
    }

    if (is.null(warehouse_id) || !nzchar(warehouse_id)) {
      if (!is.null(http_path) && nzchar(http_path)) {
        warehouse_id <- warehouse_id_from_http_path(http_path)
      } else {
        cli::cli_abort(
          "{.arg warehouse_id} or {.arg http_path} must be provided and non-empty"
        )
      }
    }

    if (!is.numeric(max_active_connections) || max_active_connections <= 0) {
      cli::cli_abort("{.arg max_active_connections} must be a positive numeric value")
    }

    if (!is.numeric(fetch_timeout) || fetch_timeout <= 0) {
      cli::cli_abort("{.arg fetch_timeout} must be a positive numeric value")
    }

    db_assert_show_progress(show_progress)

    # Validate connection by testing a simple query
    tryCatch(
      {
        test_result <- db_sql_query(
          warehouse_id = warehouse_id,
          statement = "SELECT 1 as test_connection",
          disposition = "INLINE",
          catalog = catalog,
          schema = schema,
          max_active_connections = max_active_connections,
          fetch_timeout = fetch_timeout,
          host = host,
          token = token,
          show_progress = FALSE
        )
      },
      error = function(e) {
        cli::cli_abort(
          "Failed to connect to warehouse {.val {warehouse_id}}.",
          parent = e,
          call = NULL
        )
      }
    )

    # Create connection object
    con <- new(
      "DatabricksConnection",
      warehouse_id = warehouse_id,
      host = host,
      token = token,
      catalog = catalog %||% "",
      schema = schema %||% "",
      staging_volume = staging_volume %||% "",
      disposition = disposition,
      max_active_connections = max_active_connections,
      fetch_timeout = fetch_timeout,
      show_progress = show_progress
    )

    dbi_connection_opened(con)

    con
  }
)

#' Disconnect from Databricks
#' @details Invalidates this connection and its results, including copies of the
#'   objects. Cancellation is requested for statements not known to be terminal.
#' @param conn A DatabricksConnection object
#' @param ... Additional arguments (ignored)
#' @returns `TRUE` (invisibly)
#' @export
setMethod("dbDisconnect", "DatabricksConnection", function(conn, ...) {
  if (isTRUE(conn@state$closed)) {
    cli::cli_warn("Connection is already closed.")
    return(invisible(TRUE))
  }
  if (!dbIsValid(conn)) cli::cli_warn("Connection is invalid.")
  states <- as.list(conn@state$results)
  on.exit({
    conn@state$closed <- TRUE
    purrr::walk(states, ~ db_dbi_release_state(.x, conn))
  }, add = TRUE)
  outcomes <- purrr::map(states, function(state) {
    tryCatch(db_dbi_clear_state(state, conn), error = identity)
  })
  failures <- purrr::keep(outcomes, ~ inherits(.x, "error"))
  if (length(failures) > 0L) {
    cli::cli_abort("Connection closed, but cancellation of a pending statement failed.", parent = failures[[1]])
  }
  invisible(TRUE)
})

#' Check if connection is valid
#' @param dbObj A DatabricksConnection object
#' @param ... Additional arguments (ignored)
#' @returns `TRUE` if connection is valid, `FALSE` otherwise
#' @export
setMethod("dbIsValid", "DatabricksConnection", function(dbObj, ...) {
  !isTRUE(dbObj@state$closed) && isTRUE(nzchar(dbObj@warehouse_id)) && isTRUE(nzchar(dbObj@host))
})


#' Show method for DatabricksConnection
#' @param object A DatabricksConnection object
#' @export
setMethod("show", "DatabricksConnection", function(object) {
  cat("<DatabricksConnection>\n")
  cat("  Warehouse ID:", object@warehouse_id, "\n")
  cat("  Host:", object@host, "\n")
  if (nzchar(object@catalog)) {
    cat("  Catalog:", object@catalog, "\n")
  }
  if (nzchar(object@schema)) {
    cat("  Schema:", object@schema, "\n")
  }
  if (!is.null(object@staging_volume) && nzchar(object@staging_volume)) {
    cat("  Staging Volume:", object@staging_volume, "\n")
  }
  cat("  Disposition:", object@disposition, "\n")
  cat("  Max Active Connections:", object@max_active_connections, "\n")
  cat("  Fetch Timeout (s):", object@fetch_timeout, "\n")
  cat("  Show Progress:", object@show_progress, "\n")
})

# Query Methods ----------------------------------------------------------------

#' Send query to Databricks (asynchronous)
#' @param conn A DatabricksConnection object
#' @param statement SQL statement to execute
#' @param disposition Query disposition mode. Defaults to the connection's
#'   `disposition` setting.
#' @param ... Additional arguments (ignored)
#' @returns A DatabricksResult object
#' @export
setMethod(
  "dbSendQuery",
  signature = c(conn = "DatabricksConnection", statement = "character"),
  function(conn, statement, disposition = conn@disposition, ...) {
    db_assert_valid_conn(conn)
    db_assert_statement(statement)
    disposition <- match.arg(disposition, c("EXTERNAL_LINKS", "INLINE"))

    # Execute query asynchronously
    resp <- db_sql_exec_query(
      warehouse_id = conn@warehouse_id,
      statement = statement,
      catalog = if (nzchar(conn@catalog)) conn@catalog else NULL,
      schema = if (nzchar(conn@schema)) conn@schema else NULL,
      disposition = disposition,
      format = if (disposition == "INLINE") "JSON_ARRAY" else "ARROW_STREAM",
      wait_timeout = "0s", # Async execution
      host = conn@host,
      token = conn@token
    )

    # Create result object
    result <- new(
      "DatabricksResult",
      statement_id = resp$statement_id,
      statement = statement,
      connection = conn,
      completed = FALSE,
      rows_fetched = 0
    )
    result@state$status <- resp
    result@state$disposition <- disposition
    result
  }
)

#' Execute SQL query and return results
#'
#' @param conn A DatabricksConnection object
#' @param statement SQL statement to execute
#' @param disposition Query disposition mode. Defaults to the connection's
#'   `disposition` setting.
#' @param show_progress If `TRUE`, show progress updates during query execution.
#'   Defaults to the connection's `show_progress` setting.
#' @param ... Additional arguments passed to underlying query execution
#' @returns A data.frame with query results
#' @export
setMethod(
  "dbGetQuery",
  signature = c(conn = "DatabricksConnection", statement = "character"),
  function(
    conn,
    statement,
    disposition = conn@disposition,
    show_progress = conn@show_progress,
    ...
  ) {
    db_assert_valid_conn(conn)
    disposition <- match.arg(disposition, c("EXTERNAL_LINKS", "INLINE"))
    db_assert_show_progress(show_progress)

    # Detect schema discovery queries (LIMIT 0) and optimize them
    if (endsWith(trimws(statement), "LIMIT 0")) {
      # Force INLINE disposition and disable progress for schema queries
      disposition <- "INLINE"
      show_progress <- FALSE
    }

    # Use unified db_sql_query function
    db_sql_query(
      warehouse_id = conn@warehouse_id,
      statement = statement,
      catalog = if (nzchar(conn@catalog)) conn@catalog else NULL,
      schema = if (nzchar(conn@schema)) conn@schema else NULL,
      return_arrow = FALSE,
      disposition = disposition,
      max_active_connections = conn@max_active_connections,
      fetch_timeout = conn@fetch_timeout,
      host = conn@host,
      token = conn@token,
      show_progress = show_progress,
      ...
    )
  }
)

# Read-only enforcement
#' Send statement to Databricks
#' @details Waits for terminal execution before returning, with unlimited polling
#'   for long-running writes. Use [dbGetRowsAffected()] for the affected-row count;
#'   statement results have no query rows to fetch. Normal [dbClearResult()] after
#'   this method returns does not cancel the completed write.
#' @param conn A DatabricksConnection object
#' @param statement SQL statement
#' @param ... Additional arguments (ignored)
#' @returns A completed DatabricksResult object for the statement.
#' @export
setMethod(
  "dbSendStatement",
  signature = c(conn = "DatabricksConnection", statement = "character"),
  function(conn, statement, ...) {
    db_assert_valid_conn(conn)
    db_assert_statement(statement)

    # Execute statement asynchronously
    resp <- db_sql_exec_query(
      warehouse_id = conn@warehouse_id,
      statement = statement,
      catalog = if (nzchar(conn@catalog)) conn@catalog else NULL,
      schema = if (nzchar(conn@schema)) conn@schema else NULL,
      disposition = "EXTERNAL_LINKS",
      format = "ARROW_STREAM",
      wait_timeout = "0s", # Async execution
      host = conn@host,
      token = conn@token
    )

    # Create result object
    result <- new(
      "DatabricksResult",
      statement_id = resp$statement_id,
      statement = statement,
      connection = conn,
      completed = FALSE,
      rows_fetched = 0
    )
    result@state$status <- resp
    result@state$disposition <- "EXTERNAL_LINKS"
    result@state$kind <- "statement"
    on.exit({
      if (!isTRUE(result@state$completed) &&
          isTRUE(result@state$status$status$state %in% c("FAILED", "CANCELED", "CLOSED"))) {
        db_dbi_release_state(result@state, conn)
      }
    }, add = TRUE)
    db_dbi_result_status(result)
    result@state$completed <- TRUE
    result
  }
)

#' Execute statement on Databricks
#' @param conn A DatabricksConnection object
#' @param statement SQL statement
#' @param ... Additional arguments (ignored)
#' @returns Number of rows in result set (from metadata, without loading data)
#' @export
setMethod(
  "dbExecute",
  signature = c(conn = "DatabricksConnection", statement = "character"),
  function(conn, statement, ...) {
    db_assert_valid_conn(conn)
    db_assert_statement(statement)

    # Execute statement synchronously to get metadata without loading data
    status <- db_sql_exec_and_wait(
      warehouse_id = conn@warehouse_id,
      statement = statement,
      catalog = if (nzchar(conn@catalog)) conn@catalog else NULL,
      schema = if (nzchar(conn@schema)) conn@schema else NULL,
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
#' @param n Maximum number of remaining rows to fetch. Use `-1` or `Inf` for
#'   all remaining rows, `0` for the empty schema, or `NA` for up to 1,000 rows.
#' @param show_progress If `TRUE`, show progress updates during result fetching.
#'   Defaults to the connection's `show_progress` setting.
#' @param ... Additional arguments (ignored)
#' @details Successive fetches advance a shared cursor, including when the result
#'   object is copied. Only the current chunk is retained between fetches; chunks
#'   already consumed are not downloaded again. A failed fetch does not advance
#'   past rows that were not returned. Clear the result when finished.
#' @returns A data.frame containing the next rows, with the result's column types
#'   preserved when no rows remain. Fetching a cleared result raises an error.
#' @export
setMethod("dbFetch", "DatabricksResult", function(
  res,
  n = -1,
  show_progress = res@connection@show_progress,
  ...
) {
  db_assert_show_progress(show_progress)
  db_assert_valid_result(res)
  n <- db_dbi_fetch_count(n)
  state <- res@state
  if (identical(state$kind, "statement")) {
    cli::cli_warn("Results from {.fun dbSendStatement} have no rows to fetch; use {.fun dbGetRowsAffected}.")
    return(data.frame())
  }
  if (state$completed && is.null(state$status)) return(state$ptype)
  status <- db_dbi_result_status(res, show_progress)
  if (!isTRUE(state$initialized)) {
    state$inline <- identical(status$manifest$format, "JSON_ARRAY") ||
      (is.null(status$manifest$format) && identical(state$disposition %||% res@connection@disposition, "INLINE"))
    state$ptype <- if (state$inline) {
      db_sql_process_inline(list(data_array = list()), status$manifest)
    } else {
      db_sql_create_empty_result(status$manifest)
    }
    state$next_result <- status$result
    state$initialized <- TRUE
    state$completed <- isTRUE(status$manifest$total_row_count == 0)
  }
  if (n == 0 || state$completed) return(state$ptype)

  # Commit cursor movement only after the entire fetch succeeds.
  cursor <- list2env(as.list(state), parent = emptyenv())
  pieces <- list()
  remaining <- n
  while (remaining > 0 && !cursor$completed) {
    if (is.null(cursor$buffer)) db_dbi_load_chunk(cursor, res@connection, show_progress)
    available <- nrow(cursor$buffer) - cursor$buffer_pos
    count <- min(available, remaining)
    if (count > 0) {
      rows <- cursor$buffer_pos + seq_len(count)
      pieces[[length(pieces) + 1L]] <- cursor$buffer[rows, , drop = FALSE]
      cursor$buffer_pos <- cursor$buffer_pos + count
      cursor$rows_fetched <- cursor$rows_fetched + count
      remaining <- remaining - count
    }
    if (cursor$buffer_pos == nrow(cursor$buffer)) {
      cursor$buffer <- NULL
      cursor$buffer_pos <- 0
      cursor$completed <- is.null(cursor$next_chunk_index)
    }
  }
  results <- if (length(pieces) == 0L) cursor$ptype else db_dbi_bind_rows(pieces)
  if (length(pieces) > 0L) cursor$ptype <- results[0, , drop = FALSE]
  purrr::walk(ls(cursor), function(name) state[[name]] <- cursor[[name]])
  results
})

db_dbi_fetch_count <- function(n) {
  if (length(n) != 1L || !(is.numeric(n) || identical(n, NA)) || is.complex(n) || is.nan(n) ||
      (!is.na(n) && (n < -1 || (is.finite(n) && n != floor(n))))) {
    cli::cli_abort("{.arg n} must be a non-negative integer, {.val -1}, {.val Inf}, or {.val NA}.")
  }
  if (is.na(n)) 1000 else if (n == -1) Inf else n
}

db_dbi_result_status <- function(res, show_progress = FALSE) {
  status <- res@state$status
  if (!isTRUE(status$status$state %in% c("SUCCEEDED", "FAILED", "CANCELED", "CLOSED"))) {
    status <- db_sql_exec_status(res@statement_id, host = res@connection@host, token = res@connection@token)
    if (isTRUE(status$status$state %in% c("RUNNING", "PENDING"))) {
      status <- db_sql_exec_poll_for_success(res@statement_id, show_progress = show_progress,
        host = res@connection@host, token = res@connection@token)
    }
    res@state$status <- status
  }
  if (!identical(status$status$state, "SUCCEEDED")) {
    detail <- status$status$error$message %||% "Inspect the statement status before retrying."
    state <- status$status$state %||% "unknown"
    cli::cli_abort("Statement {.val {res@statement_id}} is {.val {state}}. {detail}")
  }
  status
}

db_dbi_load_chunk <- function(cursor, conn, show_progress) {
  index <- cursor$next_chunk_index
  if (is.null(index) || index %in% cursor$seen) cli::cli_abort("Result returned a missing or repeated chunk index.")
  result <- cursor$next_result
  if (is.null(result)) result <- db_sql_exec_result(cursor$statement_id, index, host = conn@host, token = conn@token)
  expected <- purrr::detect(cursor$status$manifest$chunks, ~ .x$chunk_index == index)$row_count
  if (cursor$inline) {
    if (!is.null(result$chunk_index) && result$chunk_index != index) cli::cli_abort("Result returned an unexpected chunk index.")
    buffer <- db_sql_process_inline(result, cursor$status$manifest)
    offset <- result$row_offset
    expected <- expected %||% result$row_count
    next_index <- result$next_chunk_index
  } else {
    links <- result$external_links
    link <- purrr::detect(links, ~ identical(as.integer(.x$chunk_index), as.integer(index)))
    if (is.null(link) && length(links) == 1L && is.null(links[[1]]$chunk_index)) link <- links[[1]]
    if (is.null(link)) cli::cli_abort("Missing external link for result chunk {index}.")
    if (!is.null(link$expiration)) {
      expiration <- db_sql_parse_inline_timestamp(link$expiration)
      if (is.na(expiration) || expiration <= Sys.time()) {
        result <- db_sql_exec_result(cursor$statement_id, index, host = conn@host, token = conn@token)
        link <- purrr::detect(result$external_links, ~ identical(as.integer(.x$chunk_index), as.integer(index)))
        if (is.null(link)) cli::cli_abort("Missing refreshed external link for result chunk {index}.")
      }
    }
    expected <- expected %||% link$row_count
    link$row_count <- expected
    buffer <- db_sql_download_external_batch(links = list(link), row_limit = Inf,
      return_arrow = FALSE, max_active_connections = 1L,
      fetch_timeout = conn@fetch_timeout, show_progress = show_progress)[[1]]
    offset <- link$row_offset
    next_index <- link$next_chunk_index %||% result$next_chunk_index
  }
  if (!is.null(offset) && offset != cursor$loaded_rows) cli::cli_abort("Result chunk offset does not match the rows loaded.")
  if (!is.null(expected) && expected != nrow(buffer)) cli::cli_abort("Result chunk row count does not match its metadata.")
  cursor$loaded_rows <- cursor$loaded_rows + nrow(buffer)
  total_chunks <- cursor$status$manifest$total_chunk_count
  if (is.null(next_index) && !is.null(total_chunks) && index + 1L < total_chunks) next_index <- index + 1L
  total_rows <- cursor$status$manifest$total_row_count
  if (is.null(next_index) && !is.null(total_rows) && cursor$loaded_rows < total_rows) {
    cli::cli_abort("Result ended before all {total_rows} rows were available.")
  }
  cursor$seen <- c(cursor$seen, index)
  cursor$next_chunk_index <- next_index
  cursor$next_result <- NULL
  cursor$status$result <- NULL
  cursor$buffer <- buffer
  cursor$ptype <- buffer[0, , drop = FALSE]
}

db_dbi_bind_rows <- function(pieces) {
  if (length(pieces) == 1L) return(pieces[[1]])
  columns <- names(pieces[[1]])
  pieces <- purrr::map(pieces, ~ rlang::set_names(.x, as.character(seq_along(.x))))
  result <- dplyr::bind_rows(pieces)
  names(result) <- columns
  result
}

db_assert_valid_result <- function(res) {
  if (!dbIsValid(res)) cli::cli_abort("Result is closed or its connection is no longer valid. Submit a new query on an open connection.")
}

db_dbi_clear_state <- function(state, conn) {
  on.exit(db_dbi_release_state(state, conn), add = TRUE)
  if (!isTRUE(state$status$status$state %in% c("SUCCEEDED", "FAILED", "CANCELED", "CLOSED"))) {
    tryCatch(
      db_sql_exec_cancel(state$statement_id, host = conn@host, token = conn@token),
      error = function(error) cli::cli_abort(
        "Result closed, but cancellation of statement {.val {state$statement_id}} failed. Inspect it with {.fun db_sql_exec_status}.",
        parent = error)
    )
  }
  invisible(TRUE)
}

db_dbi_release_state <- function(state, conn) {
  state$closed <- TRUE
  state$buffer <- NULL
  state$ptype <- NULL
  state$next_result <- NULL
  state$status <- NULL
  if (exists(state$statement_id, envir = conn@state$results, inherits = FALSE)) {
    rm(list = state$statement_id, envir = conn@state$results)
  }
  invisible(TRUE)
}

#' Check whether all query rows have been fetched
#' @param res A DatabricksResult object
#' @param ... Additional arguments (ignored)
#' @returns `TRUE` when no rows remain to be fetched, `FALSE` otherwise. Server
#'   execution completing does not complete a result that still has unread rows.
#'   Results from [dbSendStatement()] always return `TRUE`.
#' @export
setMethod("dbHasCompleted", "DatabricksResult", function(res, ...) {
  db_assert_valid_result(res)
  identical(res@state$kind, "statement") || res@state$completed ||
    isTRUE(res@state$status$manifest$total_row_count == 0)
})

#' Clear result set
#' @details Invalidates all copies of the result and releases buffered rows.
#'   Cancellation is requested if the statement is not known to be terminal.
#'   Local state is cleared even if cancellation fails; the error identifies
#'   the statement to inspect. Clearing an already cleared result warns.
#' @param res A DatabricksResult object
#' @param ... Additional arguments (ignored)
#' @returns `TRUE` (invisibly)
#' @export
setMethod("dbClearResult", "DatabricksResult", function(res, ...) {
  if (isTRUE(res@state$closed)) {
    cli::cli_warn("Result is already cleared.")
    return(invisible(TRUE))
  }
  db_dbi_clear_state(res@state, res@connection)
})

#' Check whether a Databricks result is valid
#' @param dbObj A DatabricksResult object
#' @param ... Additional arguments (ignored)
#' @returns `TRUE` until the result is cleared or its connection is disconnected.
#' @family DBI Backend
#' @export
setMethod("dbIsValid", "DatabricksResult", function(dbObj, ...) {
  !isTRUE(dbObj@state$closed) && dbIsValid(dbObj@connection)
})

#' Get SQL statement from result
#' @param res A DatabricksResult object
#' @param ... Additional arguments (ignored)
#' @returns The SQL statement as character
#' @export
setMethod("dbGetStatement", "DatabricksResult", function(res, ...) {
  db_assert_valid_result(res)
  res@statement
})

#' Get number of rows fetched
#' @param res A DatabricksResult object
#' @param ... Additional arguments (ignored)
#' @returns Cumulative number of rows returned by successful fetches from this
#'   result, shared across copies of the result object.
#' @export
setMethod("dbGetRowCount", "DatabricksResult", function(res, ...) {
  db_assert_valid_result(res)
  res@state$rows_fetched
})

#' Get number of rows affected by a statement
#' @param res A DatabricksResult object
#' @param ... Additional arguments (ignored)
#' @returns The reported affected row count for statement results, or zero when
#'   no affected-row field is returned. Query results return `-1`.
#' @export
setMethod("dbGetRowsAffected", "DatabricksResult", function(res, ...) {
  db_assert_valid_result(res)
  if (!identical(res@state$kind, "statement")) return(-1)
  if (!is.null(res@state$rows_affected)) return(res@state$rows_affected)
  status <- db_dbi_result_status(res)
  names <- purrr::map_chr(status$manifest$schema$columns, "name")
  count <- 0
  if ("num_affected_rows" %in% names) {
    data <- if (identical(status$manifest$format, "JSON_ARRAY") || !is.null(status$result$data_array)) {
      db_sql_fetch_inline(status, row_limit = 1, host = res@connection@host, token = res@connection@token)
    } else {
      db_sql_fetch_results(status, row_limit = 1, host = res@connection@host,
        token = res@connection@token, show_progress = FALSE)
    }
    count <- suppressWarnings(as.numeric(data$num_affected_rows))
    if (length(count) != 1L || is.na(count) || !is.finite(count) || count < 0 || count != floor(count)) {
      cli::cli_abort("Statement {.val {res@statement_id}} did not return a valid affected-row count. Inspect its result metadata.")
    }
  }
  res@state$rows_affected <- count
  count
})

#' Get column information from result
#' @param res A DatabricksResult object
#' @param ... Additional arguments (ignored)
#' @returns A data.frame with column names and types
#' @export
setMethod("dbColumnInfo", "DatabricksResult", function(res, ...) {
  db_assert_valid_result(res)
  status <- db_dbi_result_status(res)

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
  cat("  Completed:", object@state$completed, "\n")
  cat("  Closed:", object@state$closed, "\n")
  cat("  Rows fetched:", object@state$rows_fetched, "\n")
})

# Table and Database Metadata Methods -----------------------------------------

#' List tables in Databricks catalog/schema
#' @param conn A DatabricksConnection object
#' @param ... Additional arguments (ignored)
#' @returns Character vector of table names
#' @export
setMethod("dbListTables", "DatabricksConnection", function(conn, ...) {
  db_assert_valid_conn(conn)

  # Use SQL query approach (standard for DBI drivers)
  sql <- if (nzchar(conn@catalog) && nzchar(conn@schema)) {
    paste0("SHOW TABLES IN ", conn@catalog, ".", conn@schema)
  } else if (nzchar(conn@schema)) {
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
#' @returns `TRUE` if table exists, `FALSE` otherwise
#' @export
setMethod(
  "dbExistsTable",
  signature = c(conn = "DatabricksConnection", name = "character"),
  function(conn, name, ...) {
    db_assert_valid_conn(conn)

    # Clean table name - remove quotes if present
    clean_name <- db_clean_table_name(name)

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
#' @returns `TRUE` if table exists, `FALSE` otherwise
#' @export
setMethod(
  "dbExistsTable",
  signature = c(conn = "DatabricksConnection", name = "Id"),
  function(conn, name, ...) {
    db_assert_valid_conn(conn)

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

#' Check if table exists (AsIs method)
#' @param conn A DatabricksConnection object
#' @param name Table name as AsIs object (from I())
#' @param ... Additional arguments (ignored)
#' @returns `TRUE` if table exists, `FALSE` otherwise
#' @export
setMethod(
  "dbExistsTable",
  signature = c(conn = "DatabricksConnection", name = "AsIs"),
  function(conn, name, ...) {
    db_assert_valid_conn(conn)

    # Convert AsIs to character and use the character method
    char_name <- as.character(name)
    dbExistsTable(conn, char_name)
  }
)

#' Remove a Databricks table
#' @param conn A DatabricksConnection object
#' @param name Table name to remove
#' @param ... Additional arguments (ignored)
#' @returns `TRUE` invisibly on success
#' @export
setMethod(
  "dbRemoveTable",
  signature = c(conn = "DatabricksConnection", name = "character"),
  function(conn, name, ...) {
    db_assert_valid_conn(conn)

    # Clean table name - remove quotes if present
    clean_name <- db_clean_table_name(name)

    sql <- paste0("DROP TABLE ", clean_name)
    dbExecute(conn, sql)
    invisible(TRUE)
  }
)

#' Remove a Databricks table (Id method)
#' @param conn A DatabricksConnection object
#' @param name Table name as Id object
#' @param ... Additional arguments (ignored)
#' @returns `TRUE` invisibly on success
#' @export
setMethod(
  "dbRemoveTable",
  signature = c(conn = "DatabricksConnection", name = "Id"),
  function(conn, name, ...) {
    db_assert_valid_conn(conn)

    # Convert Id to quoted string
    quoted_name <- dbQuoteIdentifier(conn, name)

    sql <- paste0("DROP TABLE ", quoted_name)
    dbExecute(conn, sql)
    invisible(TRUE)
  }
)

#' Remove a Databricks table (AsIs method)
#' @param conn A DatabricksConnection object
#' @param name Table name as AsIs object (from I())
#' @param ... Additional arguments (ignored)
#' @returns `TRUE` invisibly on success
#' @export
setMethod(
  "dbRemoveTable",
  signature = c(conn = "DatabricksConnection", name = "AsIs"),
  function(conn, name, ...) {
    db_assert_valid_conn(conn)

    # Convert AsIs to character and use the character method
    char_name <- as.character(name)
    dbRemoveTable(conn, char_name)
  }
)

#' Read a Databricks table
#' @param conn A DatabricksConnection object
#' @param name Table name to read
#' @param ... Additional arguments passed to dbGetQuery
#' @returns A data.frame with table contents
#' @export
setMethod(
  "dbReadTable",
  signature = c(conn = "DatabricksConnection", name = "character"),
  function(conn, name, ...) {
    db_assert_valid_conn(conn)

    # Clean table name - remove quotes if present
    clean_name <- db_clean_table_name(name)

    sql <- paste0("SELECT * FROM ", clean_name)
    dbGetQuery(conn, sql, ...)
  }
)

#' Read a Databricks table (Id method)
#' @param conn A DatabricksConnection object
#' @param name Table name as Id object
#' @param ... Additional arguments passed to dbGetQuery
#' @returns A data.frame with table contents
#' @export
setMethod(
  "dbReadTable",
  signature = c(conn = "DatabricksConnection", name = "Id"),
  function(conn, name, ...) {
    db_assert_valid_conn(conn)

    # Convert Id to quoted string
    quoted_name <- dbQuoteIdentifier(conn, name)

    sql <- paste0("SELECT * FROM ", quoted_name)
    dbGetQuery(conn, sql, ...)
  }
)

#' Read a Databricks table (AsIs method)
#' @param conn A DatabricksConnection object
#' @param name Table name as AsIs object (from I())
#' @param ... Additional arguments passed to dbGetQuery
#' @returns A data.frame with table contents
#' @export
setMethod(
  "dbReadTable",
  signature = c(conn = "DatabricksConnection", name = "AsIs"),
  function(conn, name, ...) {
    db_assert_valid_conn(conn)

    # Convert AsIs to character and use the character method
    char_name <- as.character(name)
    dbReadTable(conn, char_name, ...)
  }
)

#' Create an empty Databricks table
#' @param conn A DatabricksConnection object
#' @param name Table name to create
#' @param fields Either a named character vector of types or a data frame
#' @param row.names Ignored (included for DBI compatibility)
#' @param temporary If `TRUE`, create temporary table (NOT SUPPORTED - will error)
#' @param ... Additional arguments (ignored)
#' @returns `TRUE` invisibly on success
#' @export
setMethod(
  "dbCreateTable",
  signature = c(conn = "DatabricksConnection", name = "character"),
  function(conn, name, fields, ..., row.names = NULL, temporary = FALSE) {
    db_assert_valid_conn(conn)

    if (temporary) {
      cli::cli_abort(
        "Temporary tables are not supported with the SQL Statement Execution API"
      )
    }

    # Clean table name - remove quotes if present
    clean_name <- db_clean_table_name(name)
    fields_info <- db_prepare_create_table_fields(fields)
    db_create_table_from_data(
      conn,
      clean_name,
      fields_info$value,
      fields_info$field_types,
      temporary = temporary,
      overwrite = FALSE
    )
    invisible(TRUE)
  }
)

#' Create an empty Databricks table (Id method)
#' @param conn A DatabricksConnection object
#' @param name Table name as Id object
#' @param fields Either a named character vector of types or a data frame
#' @param row.names Ignored (included for DBI compatibility)
#' @param temporary If `TRUE`, create temporary table (NOT SUPPORTED - will error)
#' @param ... Additional arguments (ignored)
#' @returns `TRUE` invisibly on success
#' @export
setMethod(
  "dbCreateTable",
  signature = c(conn = "DatabricksConnection", name = "Id"),
  function(conn, name, fields, ..., row.names = NULL, temporary = FALSE) {
    db_assert_valid_conn(conn)

    if (temporary) {
      cli::cli_abort(
        "Temporary tables are not supported with the SQL Statement Execution API"
      )
    }

    # Convert Id to quoted string
    quoted_name <- dbQuoteIdentifier(conn, name)
    fields_info <- db_prepare_create_table_fields(fields)
    db_create_table_from_data(
      conn,
      quoted_name,
      fields_info$value,
      fields_info$field_types,
      temporary = temporary,
      overwrite = FALSE
    )
    invisible(TRUE)
  }
)

#' Create an empty Databricks table (AsIs method)
#' @param conn A DatabricksConnection object
#' @param name Table name as AsIs object (from I())
#' @param fields Either a named character vector of types or a data frame
#' @param row.names Ignored (included for DBI compatibility)
#' @param temporary If `TRUE`, create temporary table (NOT SUPPORTED - will error)
#' @param ... Additional arguments (ignored)
#' @returns `TRUE` invisibly on success
#' @export
setMethod(
  "dbCreateTable",
  signature = c(conn = "DatabricksConnection", name = "AsIs"),
  function(conn, name, fields, ..., row.names = NULL, temporary = FALSE) {
    db_assert_valid_conn(conn)

    # Convert AsIs to character and use the character method
    char_name <- as.character(name)
    dbCreateTable(conn, char_name, fields, temporary = temporary, ...)
  }
)

#' Get connection information
#' @param dbObj A DatabricksConnection object
#' @param ... Additional arguments (ignored)
#' @returns A list with connection details
#' @export
setMethod("dbGetInfo", "DatabricksConnection", function(dbObj, ...) {
  list(
    db.version = "Databricks SQL",
    dbname = paste0(
      dbObj@catalog,
      if (nzchar(dbObj@catalog) && nzchar(dbObj@schema)) "." else "",
      dbObj@schema
    ),
    username = NA_character_,
    host = dbObj@host,
    port = NA_integer_,
    warehouse_id = dbObj@warehouse_id,
    disposition = dbObj@disposition,
    show_progress = dbObj@show_progress
  )
})

#' List column names of a Databricks table
#' @param conn A DatabricksConnection object
#' @param name Table name to describe
#' @param ... Additional arguments (ignored)
#' @returns Character vector of column names
#' @export
setMethod(
  "dbListFields",
  signature = c(conn = "DatabricksConnection", name = "character"),
  function(conn, name, ...) {
    db_assert_valid_conn(conn)

    # Clean table name - remove quotes if present
    clean_name <- db_clean_table_name(name)

    # Use DESCRIBE TABLE to get column information with inline disposition
    sql <- paste0("DESCRIBE TABLE ", clean_name)
    result <- db_sql_query(
      warehouse_id = conn@warehouse_id,
      statement = sql,
      catalog = if (nzchar(conn@catalog)) conn@catalog else NULL,
      schema = if (nzchar(conn@schema)) conn@schema else NULL,
      return_arrow = FALSE,
      disposition = "INLINE",
      max_active_connections = conn@max_active_connections,
      fetch_timeout = conn@fetch_timeout,
      host = conn@host,
      token = conn@token,
      show_progress = FALSE
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

#' List column names of a Databricks table (AsIs method)
#' @param conn A DatabricksConnection object
#' @param name Table name as AsIs object (from I())
#' @param ... Additional arguments (ignored)
#' @returns Character vector of column names
#' @export
setMethod(
  "dbListFields",
  signature = c(conn = "DatabricksConnection", name = "AsIs"),
  function(conn, name, ...) {
    db_assert_valid_conn(conn)

    # Convert AsIs to character and use the character method
    char_name <- as.character(name)
    dbListFields(conn, char_name)
  }
)

# Transaction methods (not supported)
#' Begin transaction (not supported)
#' @param conn A DatabricksConnection object
#' @param ... Additional arguments (ignored)
#' @returns Always throws an error (transactions not supported)
#' @export
setMethod("dbBegin", "DatabricksConnection", function(conn, ...) {
  cli::cli_abort("Transactions are not supported")
})

#' Commit transaction (not supported)
#' @param conn A DatabricksConnection object
#' @param ... Additional arguments (ignored)
#' @returns Always throws an error (transactions not supported)
#' @export
setMethod("dbCommit", "DatabricksConnection", function(conn, ...) {
  cli::cli_abort("Transactions are not supported")
})

#' Rollback transaction (not supported)
#' @param conn A DatabricksConnection object
#' @param ... Additional arguments (ignored)
#' @returns Always throws an error (transactions not supported)
#' @export
setMethod("dbRollback", "DatabricksConnection", function(conn, ...) {
  cli::cli_abort("Transactions are not supported")
})

# Additional utility methods

#' Assert that a connection is valid
#' @keywords internal
db_assert_valid_conn <- function(conn) {
  if (!dbIsValid(conn)) {
    cli::cli_abort("Connection is not valid")
  }
}

#' Assert that a statement is provided
#' @keywords internal
db_assert_statement <- function(statement) {
  if (missing(statement) || is.null(statement) || !nzchar(trimws(statement))) {
    cli::cli_abort("{.arg statement} must be provided and non-empty")
  }
}

#' Assert that a progress flag is valid
#' @keywords internal
db_assert_show_progress <- function(show_progress) {
  if (
    !is.logical(show_progress) ||
      length(show_progress) != 1L ||
      is.na(show_progress)
  ) {
    cli::cli_abort("{.arg show_progress} must be `TRUE` or `FALSE`.")
  }
}

#' Extract warehouse ID from an http_path
#' @keywords internal
warehouse_id_from_http_path <- function(http_path) {
  if (is.null(http_path) || !nzchar(http_path)) {
    cli::cli_abort("{.arg http_path} must be provided and non-empty")
  }

  sub("^/sql/1\\.0/warehouses/", "", http_path)
}

#' Clean table name input
#' @keywords internal
db_clean_table_name <- function(name) {
  gsub('^\"|\"$', '', name)
}

# Check whether an R column represents Databricks binary values.
db_is_binary_column <- function(x) {
  if (inherits(x, "blob") || is.raw(x)) {
    return(TRUE)
  }

  is.list(x) &&
    purrr::every(x, \(value) is.raw(value) || is.null(value)) &&
    purrr::some(x, is.raw)
}

#' Map R data types to Databricks SQL types
#' @param dbObj A DatabricksConnection object
#' @param obj R object(s) to get SQL types for
#' @param ... Additional arguments (ignored)
#' @returns Character vector of SQL type names
#' @export
setMethod("dbDataType", "DatabricksConnection", function(dbObj, obj, ...) {
  # Map R types to Databricks SQL types
  purrr::map_chr(
    obj,
    function(x) {
      if (db_is_binary_column(x)) {
        return("BINARY")
      }

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

#' Prepare fields for CREATE TABLE
#' @keywords internal
db_prepare_create_table_fields <- function(fields) {
  if (missing(fields) || is.null(fields)) {
    cli::cli_abort("{.arg fields} must be provided")
  }

  if (is.data.frame(fields)) {
    if (ncol(fields) == 0) {
      cli::cli_abort("{.arg fields} must contain at least one column")
    }
    list(value = fields, field_types = NULL)
  } else if (is.character(fields)) {
    if (length(fields) == 0) {
      cli::cli_abort("{.arg fields} must contain at least one column")
    }
    field_names <- names(fields)
    if (
      is.null(field_names) ||
        any(is.na(field_names) | !nzchar(field_names))
    ) {
      cli::cli_abort(
        "{.arg fields} must be a named character vector when provided as character"
      )
    }
    empty_cols <- setNames(
      replicate(length(fields), logical(0), simplify = FALSE),
      field_names
    )
    value <- as.data.frame(empty_cols, stringsAsFactors = FALSE)
    list(value = value, field_types = fields)
  } else {
    cli::cli_abort("{.arg fields} must be a data frame or named character vector")
  }
}

# Identifier Quoting Methods ----------------------------------------------------

#' Quote identifiers for Databricks SQL
#' @param conn A DatabricksConnection object
#' @param x Character vector of identifiers to quote
#' @param ... Additional arguments (ignored)
#' @returns SQL object with quoted identifiers
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
        parts <- strsplit(single_x, ".", fixed = TRUE)[[1]]
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
#' @returns The SQL object unchanged
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
#' @returns SQL object with quoted identifier components
#' @export
setMethod(
  "dbQuoteIdentifier",
  signature("DatabricksConnection", "Id"),
  function(conn, x, ...) {
    # Handle schema.table identifiers
    names <- purrr::map_chr(x@name, \(x) paste0("`", x, "`"))
    DBI::SQL(paste(names, collapse = "."))
  }
)

# Write Methods ----------------------------------------------------------------

#' Write a data frame to Databricks table
#' @param conn A DatabricksConnection object
#' @param name Table name (character, Id, or SQL)
#' @param value Data frame to write
#' @param overwrite If `TRUE`, overwrite existing table
#' @param append If `TRUE`, append to existing table
#' @param row.names If `TRUE`, preserve row names as a column
#' @param temporary If `TRUE`, create temporary table (NOT SUPPORTED - will error)
#' @param field.types Named character vector of SQL types for columns
#' @param staging_volume Optional volume path for large dataset staging
#' @param show_progress If `TRUE`, show progress updates while writing.
#'   Defaults to the connection's `show_progress` setting.
#' @param ... Additional arguments.
#' @returns `TRUE` invisibly on success
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
    show_progress = conn@show_progress,
    ...
  ) {
    dots <- list(...)
    if ("progress" %in% names(dots)) {
      cli::cli_abort("Argument {.arg progress} is not supported; use {.arg show_progress}.")
    }
    db_assert_valid_conn(conn)
    db_assert_show_progress(show_progress)

    # Validate inputs
    if (overwrite && append) {
      cli::cli_abort("Cannot specify both {.code overwrite = TRUE} and {.code append = TRUE}")
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
          "Cannot preserve row names: column {.val .row_names} already exists"
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
    } else if (nzchar(conn@staging_volume)) {
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
        "Table {.val {quoted_name}} does not exist. Cannot append to non-existing table."
      )
    }

    # Check if we should use volume-based method
    if (
      db_should_use_volume_method(value, effective_staging_volume, temporary)
    ) {
      db_write_table_volume(
        conn = conn,
        quoted_name = quoted_name,
        value = value,
        staging_volume = effective_staging_volume,
        append = append,
        show_progress = show_progress
      )
    } else {
      db_write_table_standard(
        conn,
        quoted_name,
        value,
        overwrite,
        append,
        field.types,
        temporary,
        show_progress = show_progress
      )
    }

    invisible(TRUE)
  }
)

#' Write a data frame to Databricks table (Id method)
#' @param conn A DatabricksConnection object
#' @param name Table name as Id object
#' @param value Data frame to write
#' @param overwrite If `TRUE`, overwrite existing table
#' @param append If `TRUE`, append to existing table
#' @param row.names If `TRUE`, preserve row names as a column
#' @param temporary If `TRUE`, create temporary table (NOT SUPPORTED - will error)
#' @param field.types Named character vector of SQL types for columns
#' @param staging_volume Optional volume path for large dataset staging
#' @param show_progress If `TRUE`, show progress updates while writing.
#'   Defaults to the connection's `show_progress` setting.
#' @param ... Additional arguments.
#' @returns `TRUE` invisibly on success
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
    show_progress = conn@show_progress,
    ...
  ) {
    dots <- list(...)
    if ("progress" %in% names(dots)) {
      cli::cli_abort("Argument {.arg progress} is not supported; use {.arg show_progress}.")
    }
    db_assert_valid_conn(conn)
    db_assert_show_progress(show_progress)

    # Handle Id object by implementing the logic directly instead of delegating
    # This avoids double-quoting issues

    # Validate inputs
    if (overwrite && append) {
      cli::cli_abort("Cannot specify both {.code overwrite = TRUE} and {.code append = TRUE}")
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
    if (is.null(effective_staging_volume) && nzchar(conn@staging_volume)) {
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
        "Table {.val {quoted_name}} does not exist. Cannot append to non-existing table."
      )
    }

    # Check if we should use volume-based method
    use_staging_volume <- db_should_use_volume_method(
      value,
      effective_staging_volume,
      temporary
    )

    if (use_staging_volume) {
      if (!rlang::is_installed("arrow")) {
        cli::cli_abort(c(
          "Volume-based writes require the {.pkg arrow} package.",
          "i" = "Install it with {.code install.packages('arrow')}."
        ))
      }

      db_write_table_volume(
        conn = conn,
        quoted_name = quoted_name,
        value = value,
        staging_volume = effective_staging_volume,
        append = append,
        show_progress = show_progress
      )
    } else {
      db_write_table_standard(
        conn,
        quoted_name,
        value,
        overwrite,
        append,
        field.types,
        temporary,
        show_progress = show_progress
      )
    }

    invisible(TRUE)
  }
)

#' Write table to Databricks (AsIs name signature)
#' @param conn DatabricksConnection object
#' @param name Table name as AsIs object (from I())
#' @param value Data frame to write
#' @param overwrite If `TRUE`, overwrite existing table
#' @param append If `TRUE`, append to existing table
#' @param row.names If `TRUE`, preserve row names as a column
#' @param temporary If `TRUE`, create temporary table (NOT SUPPORTED - will error)
#' @param field.types Named character vector of SQL types for columns
#' @param staging_volume Optional volume path for large dataset staging
#' @param show_progress If `TRUE`, show progress updates while writing.
#'   Defaults to the connection's `show_progress` setting.
#' @param ... Additional arguments.
#' @returns `TRUE` invisibly on success
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
    show_progress = conn@show_progress,
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
      show_progress = show_progress,
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
  temporary = FALSE,
  show_progress = TRUE
) {
  if (temporary) {
    cli::cli_abort(
      "Temporary tables are not supported with the SQL Statement Execution API"
    )
  }

  # Show progress for table creation
  if (show_progress) {
    cli::cli_progress_step(
      if (append) "Appending data to table" else "Creating table"
    )
  }

  if (append) {
    # For append, use atomic INSERT INTO with SELECT VALUES
    if (nrow(value) > 0) {
      db_append_with_select_values(conn, quoted_name, value)
    }
  } else {
    # For create/overwrite, explicitly create schema then insert rows
    db_create_table_as_select_values(
      conn,
      quoted_name,
      value,
      field.types,
      temporary,
      overwrite
    )
  }

  if (show_progress) {
    cli::cli_progress_done()
  }
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
    col_types <- dbDataType(conn, value)
  } else {
    # Use provided types
    col_types <- field.types[names(value)]
    # Fill missing types with automatic mapping
    missing_types <- is.na(col_types) | !names(value) %in% names(field.types)
    if (any(missing_types)) {
      col_types[missing_types] <- dbDataType(conn, value[missing_types])
    }
  }

  # Build column definitions
  col_names <- purrr::map_chr(names(value), \(x) dbQuoteIdentifier(conn, x))
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


#' Generate type-aware VALUES SQL from data frame
#' @keywords internal
db_generate_typed_values_sql <- function(conn, data) {
  # Convert each row to SQL values with proper typing
  row_values <- purrr::pmap_chr(data, function(...) {
    row <- list(...)
    values <- purrr::imap_chr(row, function(val, col_name) {
      db_format_typed_value_sql(conn, val, data[[col_name]])
    })
    paste0("(", paste(values, collapse = ", "), ")")
  })

  paste(row_values, collapse = ", ")
}

# Format a single R value for inline SQL VALUES.
db_format_typed_value_sql <- function(conn, val, col_data) {
  if (db_is_missing_sql_value(val)) {
    "NULL"
  } else if (db_is_binary_column(col_data)) {
    db_binary_literal(val)
  } else if (is.logical(col_data)) {
    if (as.logical(val)) "TRUE" else "FALSE"
  } else if (is.numeric(col_data)) {
    # Don't quote numeric values to preserve type
    as.character(val)
  } else if (is.character(col_data)) {
    # Quote string values and escape single quotes
    db_escape_string_literal(conn, val)
  } else {
    # Default to quoted string for other types
    db_escape_string_literal(conn, as.character(val))
  }
}

# Check whether a row value should be rendered as SQL NULL.
db_is_missing_sql_value <- function(val) {
  is.null(val) || (length(val) == 1L && is.na(val))
}

# Format raw bytes as a Databricks binary literal.
db_binary_literal <- function(val) {
  if (!is.raw(val)) {
    cli::cli_abort("Binary columns must contain raw vectors or `NULL` values.")
  }

  paste0("X'", paste(toupper(as.character(val)), collapse = ""), "'")
}

#' Escape string literals for inline SQL VALUES
#' @keywords internal
db_escape_string_literal <- function(conn, val) {
  if (is.na(val)) {
    return("NULL")
  }

  # Spark SQL accepts backslash-escaped quotes; escape backslashes first
  escaped <- gsub("\\", "\\\\", val, fixed = TRUE)
  escaped <- gsub("'", "\\'", escaped, fixed = TRUE)
  paste0("'", escaped, "'")
}

#' Create table with explicit schema before inserting values
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

  # First create the table with explicit column definitions to avoid
  # Databricks inferring overly specific types (e.g., DECIMAL(6, 4)).
  db_create_table_from_data(
    conn,
    quoted_name,
    value,
    field.types,
    temporary,
    overwrite
  )

  # Nothing more to do if there are no rows to insert after seeding.
  if (nrow(value) == 0) {
    return(invisible(NULL))
  }

  # Populate the newly created table using INSERT ... SELECT ... VALUES so that
  # the schema we just created is preserved for future appends.
  db_append_with_select_values(conn, quoted_name, value)
}

#' Append data using atomic INSERT INTO with SELECT VALUES
#' @keywords internal
db_append_with_select_values <- function(conn, quoted_name, value) {
  # Get column names with proper quoting
  col_names <- purrr::map_chr(names(value), \(x) dbQuoteIdentifier(conn, x))
  col_list <- paste(col_names, collapse = ", ")

  # Generate VALUES clause with type-aware formatting
  values_sql <- db_generate_typed_values_sql(conn, value)

  # Build atomic INSERT statement
  insert_sql <- paste0(
    "INSERT INTO ",
    quoted_name,
    " (",
    col_list,
    ") VALUES ",
    values_sql
  )

  # Execute using helper function
  db_sql_exec_and_wait(
    warehouse_id = conn@warehouse_id,
    statement = insert_sql,
    catalog = if (nzchar(conn@catalog)) conn@catalog else NULL,
    schema = if (nzchar(conn@schema)) conn@schema else NULL,
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
  has_volume <- !is.null(staging_volume) && nzchar(staging_volume)

  # Always use a staging volume if its specified, regardless of size
  if (has_volume) {
    return(TRUE)
  }

  # Temporary tables should use standard method (COPY INTO may not support them)
  if (temporary) {
    return(FALSE)
  }

  # Check dataset size limits without volume staging
  if (!has_volume) {
    if (n_rows > 50000) {
      # Fail for very large datasets
      cli::cli_abort(c(
        "Cannot write {n_rows} rows without volume staging.",
        "x" = "Standard SQL method is not suitable for datasets larger than 50,000 rows.",
        "i" = "Use the {.arg staging_volume} parameter to enable volume-based uploads.",
        "i" = "Example: {.code dbWriteTable(conn, name, data, staging_volume = '/Volumes/catalog/schema/volume')}"
      ))
    } else if (n_rows >= 20000) {
      # Warn about performance for medium-large datasets
      cli::cli_warn(c(
        "Writing {n_rows} rows using standard SQL method will be slow.",
        "i" = "Consider using {.arg staging_volume} parameter for better performance.",
        "i" = "Example: {.code dbWriteTable(conn, name, data, staging_volume = '/Volumes/catalog/schema/volume')}"
      ))
    }
  }

  FALSE
}

#' Write table using volume-based approach
#' @keywords internal
db_write_table_volume <- function(
  conn,
  quoted_name,
  value,
  staging_volume,
  append = FALSE,
  show_progress = TRUE
) {
  db_assert_show_progress(show_progress)

  # Validate volume path
  staging_volume <- is_valid_volume_path(staging_volume)

  if (
    !db_volume_dir_exists(staging_volume, host = conn@host, token = conn@token)
  ) {
    cli::cli_abort("Staging volume directory does not exist: {.path {staging_volume}}")
  }

  # Generate unique directory name for dataset
  temp_dirname <- paste0(
    "brickster_upload_",
    format(Sys.time(), "%Y%m%d_%H%M%S"),
    "_",
    sample(10000:99999, 1)
  )

  volume_dataset_path <- fs::path(staging_volume, temp_dirname)
  local_temp_dir <- fs::path(fs::path_temp(), temp_dirname)

  # Set up cleanup hooks to ensure cleanup happens even if there are errors
  on.exit(
    {
      # Cleanup local directory
      if (fs::dir_exists(local_temp_dir)) {
        fs::dir_delete(local_temp_dir)
      }

      # Clean up volume directory (recursive since it contains files)
      # Use tryCatch to avoid errors during cleanup from stopping the exit handler
      if (show_progress) {
        cli::cli_progress_step("Clearing staged files")
      }

      tryCatch(
        {
          db_volume_dir_delete(
            volume_dataset_path,
            recursive = TRUE,
            host = conn@host,
            token = conn@token
          )

          if (show_progress) {
            cli::cli_progress_done()
          }
        },
        error = function(e) {
          if (show_progress) {
            cli::cli_progress_done(result = "failed")
          }

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
  if (show_progress) {
    cli::cli_progress_step("Writing files")
  }

  arrow::write_dataset(
    value,
    local_temp_dir,
    format = "parquet",
    compression = "zstd",
    max_rows_per_file = 5000000L
  )

  if (show_progress) {
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
    recursive = TRUE,
    host = conn@host,
    token = conn@token
  )

  # Execute SQL to create/populate table
  if (show_progress) {
    cli::cli_progress_step(
      if (append) {
        "Appending data to table"
      } else {
        "Creating table from uploaded data"
      },
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
      "', format => 'parquet', schemaEvolutionMode => 'none')"
    )
  }

  # Execute SQL using helper function (inline since we don't need data back)
  db_sql_exec_and_wait(
    warehouse_id = conn@warehouse_id,
    statement = copy_sql,
    catalog = if (nzchar(conn@catalog)) conn@catalog else NULL,
    schema = if (nzchar(conn@schema)) conn@schema else NULL,
    disposition = "INLINE",
    format = "JSON_ARRAY",
    wait_timeout = "10s",
    host = conn@host,
    token = conn@token,
    show_progress = FALSE
  )

  if (show_progress) cli::cli_progress_done()
}

#' Append rows to an existing Databricks table
#' @param conn A DatabricksConnection object
#' @param name Table name (character, Id, or SQL)
#' @param value Data frame to append
#' @param ... Additional arguments
#' @param row.names If `TRUE`, preserve row names as a column
#' @returns `TRUE` invisibly on success
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
        c(
          "Table {.val {name}} does not exist.",
          "i" = "Use {.fn dbWriteTable} to create it first."
        )
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
#' @param row.names If `TRUE`, preserve row names as a column
#' @returns `TRUE` invisibly on success
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
        c(
          "Table {.val {table_name}} does not exist.",
          "i" = "Use {.fn dbWriteTable} to create it first."
        )
      )
    }

    # Use dbWriteTable with append = TRUE
    dbWriteTable(conn, name, value, append = TRUE, row.names = row.names, ...)
  }
)
