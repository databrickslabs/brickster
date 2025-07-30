# https://docs.databricks.com/api/workspace/statementexecution
# https://docs.databricks.com/en/sql/admin/sql-execution-tutorial.html#language-curl

#' Execute SQL Query
#'
#' @details Refer to the
#' [web documentation](https://docs.databricks.com/api/workspace/statementexecution/executestatement)
#' for detailed material on interaction of the various parameters and general recommendations
#'
#' @param statement String, the SQL statement to execute. The statement can
#' optionally be parameterized, see `parameters`.
#' @param warehouse_id String, ID of warehouse upon which to execute a statement.
#' @param catalog String, sets default catalog for statement execution, similar
#' to `USE CATALOG` in SQL.
#' @param schema String, sets default schema for statement execution, similar
#' to `USE SCHEMA` in SQL.
#' @param parameters List of Named Lists, parameters to pass into a SQL
#' statement containing parameter markers.
#'
#' A parameter consists of a name, a value, and *optionally* a type.
#' To represent a `NULL` value, the value field may be omitted or set to `NULL`
#' explicitly.
#'
#' See [docs](https://docs.databricks.com/api/workspace/statementexecution/executestatement)
#' for more details.
#' @param row_limit Integer, applies the given row limit to the statement's
#' result set, but unlike the `LIMIT` clause in SQL, it also sets the
#' `truncated` field in the response to indicate whether the result was trimmed
#' due to the limit or not.
#' @param byte_limit Integer, applies the given byte limit to the statement's
#' result size. Byte counts are based on internal data representations and
#' might not match the final size in the requested format. If the result was
#' truncated due to the byte limit, then `truncated` in the response is set to
#' true. When using `EXTERNAL_LINKS` disposition, a default byte_limit of
#' 100 GiB is applied if `byte_limit` is not explicitly set.
#' @param disposition One of `"INLINE"` (default) or `"EXTERNAL_LINKS"`. See
#' [docs](https://docs.databricks.com/api/workspace/statementexecution/executestatement)
#' for details.
#' @param format One of `"JSON_ARRAY"` (default), `"ARROW_STREAM"`, or `"CSV"`.
#' See [docs](https://docs.databricks.com/api/workspace/statementexecution/executestatement)
#' for details.
#' @param wait_timeout String, default is `"10s"`. The time in seconds the call
#' will wait for the statement's result set as `Ns`, where `N` can be set to
#' `0` or to a value between `5` and `50`.
#' When set to `0s`, the statement will execute in asynchronous mode and the
#' call will not wait for the execution to finish. In this case, the call
#' returns directly with `PENDING` state and a statement ID which can be used
#' for polling with [db_sql_exec_status()].
#'
#' When set between `5` and `50` seconds, the call will behave synchronously up
#' to this timeout and wait for the statement execution to finish. If the
#' execution finishes within this time, the call returns immediately with a
#' manifest and result data (or a `FAILED` state in case of an execution error).
#'
#' If the statement takes longer to execute, `on_wait_timeout` determines what
#' should happen after the timeout is reached.
#'
#' @param on_wait_timeout One of `"CONTINUE"` (default) or `"CANCEL"`.
#' When `wait_timeout` > `0s`, the call will block up to the specified time.
#' If the statement execution doesn't finish within this time,
#' `on_wait_timeout` determines whether the execution should continue or be
#' canceled.
#'
#' When set to `CONTINUE`, the statement execution continues asynchronously and
#' the call returns a statement ID which can be used for polling with
#' [db_sql_exec_status()].
#'
#' When set to `CANCEL`, the statement execution is canceled and the call
#' returns with a `CANCELED` state.
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @family SQL Execution APIs
#'
#' @export
db_sql_exec_query <- function(
  statement,
  warehouse_id,
  catalog = NULL,
  schema = NULL,
  parameters = NULL,
  row_limit = NULL,
  byte_limit = NULL,
  disposition = c("INLINE", "EXTERNAL_LINKS"),
  format = c("JSON_ARRAY", "ARROW_STREAM", "CSV"),
  wait_timeout = "10s",
  on_wait_timeout = c("CONTINUE", "CANCEL"),
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  disposition <- match.arg(disposition)
  format <- match.arg(format)
  on_wait_timeout <- match.arg(on_wait_timeout)

  body <- list(
    statement = statement,
    warehouse_id = warehouse_id,
    catalog = catalog,
    schema = schema,
    parameters = parameters,
    row_limit = row_limit,
    byte_limit = byte_limit,
    disposition = disposition,
    format = format,
    wait_timeout = wait_timeout,
    on_wait_timeout = on_wait_timeout
  )

  req <- db_request(
    endpoint = "sql/statements",
    method = "POST",
    version = "2.0",
    body = body,
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }
}

#' Cancel SQL Query
#'
#' @details
#' Requests that an executing statement be canceled. Callers must poll for
#' status to see the terminal state.
#'
#' [Read more on Databricks API docs](https://docs.databricks.com/api/workspace/statementexecution/cancelexecution)
#'
#' @param statement_id String, query execution `statement_id`
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @family SQL Execution APIs
#'
#' @export
db_sql_exec_cancel <- function(
  statement_id,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  req <- db_request(
    endpoint = paste0("sql/statements/", statement_id, "/cancel"),
    method = "POST",
    version = "2.0",
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }
}


#' Get SQL Query Status
#'
#' @details
#' This request can be used to poll for the statement's status.
#' When the `status.state` field is `SUCCEEDED` it will also return the result
#' manifest and the first chunk of the result data.
#'
#' When the statement is in the terminal states `CANCELED`, `CLOSED` or
#' `FAILED`, it returns HTTP `200` with the state set.
#'
#' After at least 12 hours in terminal state, the statement is removed from the
#' warehouse and further calls will receive an HTTP `404` response.
#'
#' [Read more on Databricks API docs](https://docs.databricks.com/api/workspace/statementexecution/getstatement)
#'
#' @inheritParams auth_params
#' @inheritParams db_sql_exec_cancel
#' @inheritParams db_sql_warehouse_create
#'
#' @family SQL Execution APIs
#'
#' @export
db_sql_exec_status <- function(
  statement_id,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  req <- db_request(
    endpoint = paste0("sql/statements/", statement_id),
    method = "GET",
    version = "2.0",
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }
}


#' Get SQL Query Results
#'
#' @details
#' After the statement execution has `SUCCEEDED`, this request can be used to
#' fetch any chunk by index.
#'
#' Whereas the first chunk with chunk_index = `0` is typically fetched with
#' [db_sql_exec_result()] or [db_sql_exec_status()], this request can be used
#' to fetch subsequent chunks
#'
#' The response structure is identical to the nested result element described
#' in the [db_sql_exec_result()] request, and similarly includes the
#' `next_chunk_index` and `next_chunk_internal_link` fields for simple
#' iteration through the result set.
#'
#' [Read more on Databricks API docs](https://docs.databricks.com/api/workspace/statementexecution/getstatementresultchunkn)
#'
#' @param chunk_index Integer, chunk index to fetch result. Starts from `0`.
#' @inheritParams db_sql_exec_cancel
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @family SQL Execution APIs
#'
#' @export
db_sql_exec_result <- function(
  statement_id,
  chunk_index,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  req <- db_request(
    endpoint = paste0(
      "sql/statements/",
      statement_id,
      "/result/chunks/",
      chunk_index
    ),
    method = "GET",
    version = "2.0",
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }
}

#' Poll a Query Until Successful
#'
#' @inheritParams db_sql_exec_cancel
#' @param interval Number of seconds between status checks.
db_sql_exec_poll_for_success <- function(statement_id, interval = 1) {
  is_query_running <- TRUE

  while (is_query_running) {
    Sys.sleep(interval)
    status <- db_sql_exec_status(statement_id = statement_id)
    if (status$status$state == "SUCCEEDED") {
      is_query_running <- FALSE
    } else if (status$status$state %in% c("FAILED", "CLOSED", "CANCELED")) {
      cli::cli_abort("Query failed with status: {.val {status$status$state}}")
    }
  }

  status
}


# Internal Helper Functions for SQL Execution -------------------------------

#' Execute SQL Query and Wait for Completion
#'
#' @description
#' Internal helper that executes a query and waits for completion.
#' This separates the execution/polling logic from result fetching.
#'
#' @inheritParams db_sql_exec_query
#' @param wait_timeout Initial wait timeout (default "30s")
#' @returns Status response with manifest when query completes successfully
#' @keywords internal
db_sql_exec_and_wait <- function(
  warehouse_id,
  statement,
  catalog = NULL,
  schema = NULL,
  parameters = NULL,
  row_limit = NULL,
  byte_limit = NULL,
  wait_timeout = "10s",
  disposition = c("EXTERNAL_LINKS", "INLINE"),
  format = c("ARROW_STREAM", "JSON_ARRAY"),
  host = db_host(),
  token = db_token(),
  show_progress = TRUE
) {
  # Validate arguments
  disposition <- match.arg(disposition)
  format <- match.arg(format)

  # Execute query with optional progress tracking
  if (show_progress) {
    cli::cli_progress_step(
      "Running query",
      "Query completed"
    )
  }

  resp <- db_sql_exec_query(
    warehouse_id = warehouse_id,
    statement = statement,
    disposition = disposition,
    format = format,
    wait_timeout = wait_timeout,
    on_wait_timeout = "CONTINUE",
    catalog = catalog,
    schema = schema,
    parameters = parameters,
    row_limit = row_limit,
    byte_limit = byte_limit,
    host = host,
    token = token
  )

  # Poll for completion if still running
  if (resp$status$state %in% c("RUNNING", "PENDING")) {
    if (show_progress) {
      cli::cli_progress_update("Checking status...")
    }
    resp <- db_sql_exec_poll_for_success(resp$statement_id)
  }

  # Check for query failure and complete progress
  if (resp$status$state == "FAILED") {
    if (show_progress) {
      cli::cli_progress_done(result = "failed")
    }
    cli::cli_abort(resp$status$error$message)
  }

  if (show_progress) {
    cli::cli_progress_done()
  }

  resp
}

#' Create Empty R Vector from Databricks SQL Type
#'
#' @description
#' Internal helper that maps Databricks SQL types to appropriate empty R vectors.
#' Used for creating properly typed empty tibbles from schema information.
#'
#' @param sql_type Character string representing Databricks SQL type
#' @returns Empty R vector of appropriate type
#' @keywords internal
db_sql_type_to_empty_vector <- function(sql_type) {
  sql_type <- toupper(sql_type)

  if (sql_type %in% c("BYTE", "SHORT", "INT", "LONG")) {
    integer(0)
  } else if (sql_type %in% c("FLOAT", "DOUBLE", "DECIMAL")) {
    numeric(0)
  } else if (sql_type %in% c("BOOLEAN")) {
    logical(0)
  } else if (sql_type %in% c("DATE")) {
    as.Date(character(0))
  } else if (sql_type %in% c("TIMESTAMP")) {
    as.POSIXct(character(0))
  } else if (sql_type %in% c("STRING", "BINARY", "CHAR")) {
    character(0)
  } else {
    # Default to character for complex types (ARRAY, STRUCT, MAP, INTERVAL, NULL, USER_DEFINED_TYPE)
    character(0)
  }
}

#' Process Inline SQL Query Results
#'
#' @description
#' Internal helper that processes inline JSON_ARRAY results from a completed query.
#' Used for metadata queries and small result sets.
#'
#' @param result_data Result data from inline query response
#' @param manifest Query result manifest containing schema information
#' @param row_limit Integer, limit number of rows returned
#' @returns tibble with query results
#' @keywords internal
db_sql_process_inline <- function(result_data, manifest, row_limit = NULL) {
  # Extract column names and types
  col_names <- purrr::map_chr(manifest$schema$columns, "name")

  # Convert JSON array to tibble (empty handling done upstream)
  data_list <- result_data$data_array

  # Convert to data frame
  df <- purrr::list_transpose(data_list)
  names(df) <- col_names

  # Convert to tibble
  results <- tibble::as_tibble(df)

  # Apply row limit if specified
  if (!is.null(row_limit) && row_limit > 0 && nrow(results) > row_limit) {
    results <- results[1:row_limit, ]
  }

  results
}

#' Create Empty Data Frame from Query Manifest
#'
#' @description
#' Helper function that creates an empty data frame with proper column types
#' based on the query result manifest schema. Used when query returns zero rows.
#'
#' @param manifest Query result manifest containing schema information
#' @returns tibble with zero rows but correct column types
#' @keywords internal
db_sql_create_empty_result <- function(manifest) {
  # Extract column names and types from manifest
  col_names <- purrr::map_chr(manifest$schema$columns, "name")

  # Create empty columns with proper types based on manifest
  empty_cols <- purrr::map(manifest$schema$columns, function(col) {
    # Use helper to get appropriate empty vector
    db_sql_type_to_empty_vector(col$type_name)
  })
  names(empty_cols) <- col_names

  results <- tibble::as_tibble(empty_cols)

  results
}

#' Fetch SQL Query Results from Completed Query
#'
#' @description
#' Internal helper that fetches and processes results from a completed query.
#' Handles Arrow stream processing and data conversion.
#'
#' @param statement_id Query statement ID
#' @param manifest Query result manifest from status response
#' @param return_arrow Boolean, return arrow Table instead of tibble
#' @param max_active_connections Integer for concurrent downloads
#' @param row_limit Integer, limit number of rows returned (applied after fetch)
#' @param host Databricks host
#' @param token Databricks token
#' @returns tibble or arrow Table with query results
#' @keywords internal
db_sql_fetch_results <- function(
  statement_id,
  manifest,
  return_arrow = FALSE,
  max_active_connections = 30,
  row_limit = NULL,
  host = db_host(),
  token = db_token()
) {
  # This function only handles external links disposition
  # Get chunk information (empty handling done upstream)
  total_chunks <- manifest$total_chunk_count - 1

  # Create requests for all result chunks
  reqs <- purrr::map(
    .x = seq.int(total_chunks, from = 0),
    .f = db_sql_exec_result,
    statement_id = statement_id,
    perform_request = FALSE
  )

  # Get external links (use low parallelism for link retrieval)
  resps <- httr2::req_perform_parallel(reqs, max_active = 3, progress = FALSE)

  links <- resps |>
    purrr::map(httr2::resp_body_json) |>
    purrr::map_chr(~ .x$external_links[[1]]$external_link) |>
    purrr::map(
      ~ httr2::request(.x) |>
        httr2::req_retry(max_tries = 3, backoff = ~1) |>
        httr2::req_timeout(300)
    )

  # Download with styled progress bar
  ipc_data <- httr2::req_perform_parallel(
    links,
    max_active = max_active_connections,
    progress = list(
      clear = FALSE,
      format = "Fetching {cli::pb_bar} {cli::pb_percent} [{cli::pb_elapsed}]",
      format_done = "{cli::col_green('\\u2714')} Data fetched [{cli::pb_elapsed}]",
      type = "iterator"
    )
  )

  # Process data with progress
  cli::cli_progress_step(
    "Processing query results",
    "Query results processed"
  )
  if (rlang::is_installed("arrow")) {
    # Read IPC data as arrow tables
    arrow_tbls <- ipc_data |>
      purrr::map(
        ~ arrow::read_ipc_stream(
          httr2::resp_body_raw(.x),
          as_data_frame = FALSE
        )
      )
    results <- do.call(arrow::concat_tables, arrow_tbls)

    # Convert to tibble unless arrow table requested
    if (!return_arrow) {
      results <- tibble::as_tibble(results)
    }
  } else {
    # Fallback to nanoarrow
    results <- purrr::map(
      ipc_data,
      ~ tibble::as_tibble(nanoarrow::read_nanoarrow(.x))
    ) |>
      purrr::list_rbind()
  }
  cli::cli_progress_done()

  # Apply row limit if specified
  if (!is.null(row_limit) && row_limit > 0 && nrow(results) > row_limit) {
    results <- results[1:row_limit, ]
  }

  results
}


#' Execute query with SQL Warehouse
#'
#' @inheritParams db_sql_exec_query
#' @param return_arrow Boolean, determine if result is [tibble::tibble] or
#' [arrow::Table].
#' @param max_active_connections Integer to decide on concurrent downloads.
#' @param disposition Disposition mode ("INLINE" or "EXTERNAL_LINKS")
#' @param show_progress If TRUE, show progress updates during query execution (default: TRUE)
#' @returns [tibble::tibble] or [arrow::Table].
#' @export
db_sql_query <- function(
  warehouse_id,
  statement,
  schema = NULL,
  catalog = NULL,
  parameters = NULL,
  row_limit = NULL,
  byte_limit = NULL,
  return_arrow = FALSE,
  max_active_connections = 30,
  disposition = "EXTERNAL_LINKS",
  host = db_host(),
  token = db_token(),
  show_progress = TRUE
) {
  # Choose format based on disposition
  format <- if (disposition == "INLINE") "JSON_ARRAY" else "ARROW_STREAM"

  # Execute query and wait for completion
  resp <- db_sql_exec_and_wait(
    warehouse_id = warehouse_id,
    statement = statement,
    catalog = catalog,
    schema = schema,
    parameters = parameters,
    row_limit = row_limit,
    byte_limit = byte_limit,
    wait_timeout = "10s",
    disposition = disposition,
    format = format,
    host = host,
    token = token,
    show_progress = show_progress
  )

  # Check for empty results early and return immediately
  # Use total_row_count to detect empty result sets
  if (resp$manifest$total_row_count == 0) {
    return(db_sql_create_empty_result(resp$manifest))
  }

  # Fetch and process results based on disposition
  if (disposition == "INLINE") {
    # Use inline processor for JSON_ARRAY results
    db_sql_process_inline(
      result_data = resp$result,
      manifest = resp$manifest,
      row_limit = row_limit
    )
  } else {
    # Use external links processor for ARROW_STREAM results
    db_sql_fetch_results(
      statement_id = resp$statement_id,
      manifest = resp$manifest,
      return_arrow = return_arrow,
      max_active_connections = max_active_connections,
      row_limit = row_limit,
      host = host,
      token = token
    )
  }
}
