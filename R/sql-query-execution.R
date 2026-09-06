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
#' @returns If `perform_request = TRUE`, returns endpoint-specific API output. If `FALSE`, returns an `httr2_request`.
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
  wait_timeout = "0s",
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
#' @returns If `perform_request = TRUE`, returns endpoint-specific API output. If `FALSE`, returns an `httr2_request`.
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
#' @returns If `perform_request = TRUE`, returns endpoint-specific API output. If `FALSE`, returns an `httr2_request`.
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
#' @returns If `perform_request = TRUE`, returns endpoint-specific API output. If `FALSE`, returns an `httr2_request`.
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
#' @param show_progress If `TRUE`, show progress updates during polling (default: `TRUE`)
db_sql_exec_poll_for_success <- function(
  statement_id,
  interval = 1,
  show_progress = TRUE,
  host = db_host(),
  token = db_token()
) {
  is_query_running <- TRUE

  while (is_query_running) {
    status <- db_sql_exec_status(
      statement_id = statement_id,
      host = host,
      token = token
    )

    if (status$status$state == "SUCCEEDED") {
      is_query_running <- FALSE
    } else if (status$status$state %in% c("FAILED", "CLOSED", "CANCELED")) {
      # Get the actual error message if available
      if (!is.null(status$status$error$message)) {
        error_msg <- status$status$error$message
      } else {
        error_msg <- paste("Query failed with status:", status$status$state)
      }
      cli::cli_abort(error_msg)
    } else {
      Sys.sleep(interval)
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
  wait_timeout = "0s",
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
    cli::cli_progress_step("Submitting query")
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
      cli::cli_progress_step("Executing query")
    }
    resp <- db_sql_exec_poll_for_success(
      resp$statement_id,
      interval = 0.1,
      show_progress = FALSE,
      host = host,
      token = token
    )
  }

  # Check for query failure
  if (resp$status$state == "FAILED") {
    cli::cli_abort(resp$status$error$message)
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
  columns <- manifest$schema$columns
  rows <- result_data$data_array %||% list()
  if (!is.null(row_limit) && is.finite(row_limit)) rows <- head(rows, row_limit)
  if (any(purrr::map_int(rows, length) != length(columns))) {
    cli::cli_abort("INLINE result row width does not match the manifest schema.")
  }
  values <- purrr::map(seq_along(columns), function(i) {
    column <- purrr::map_chr(rows, ~ .x[[i]] %||% NA_character_)
    db_sql_decode_inline_column(column, columns[[i]])
  })
  names(values) <- purrr::map_chr(columns, "name")
  tibble::new_tibble(values, nrow = length(rows))
}

db_sql_decode_inline_column <- function(values, column) {
  type <- toupper(column$type_name)
  if (type == "TIMESTAMP" && grepl("^TIMESTAMP_NTZ", column$type_text %||% "")) return(values)
  if (type %in% c("BYTE", "SHORT", "INT")) {
    numbers <- suppressWarnings(as.numeric(values))
    bounds <- switch(type, BYTE = c(-128, 127), SHORT = c(-32768, 32767), INT = c(-2147483648, 2147483647))
    invalid <- !is.na(values) & (is.na(numbers) | numbers != floor(numbers) |
      numbers < bounds[[1]] | numbers > bounds[[2]])
    if (any(invalid)) cli::cli_abort("Unable to decode INLINE column {.val {column$name}} as {.val {type}}.")
    # R reserves the lowest signed 32-bit integer for NA.
    return(if (any(numbers == -2147483648, na.rm = TRUE)) numbers else as.integer(numbers))
  }
  decoded <- suppressWarnings(switch(type,
    FLOAT = as.numeric(values),
    DOUBLE = as.numeric(values),
    BOOLEAN = {
      lower <- tolower(values)
      if (any(!is.na(lower) & !lower %in% c("true", "false"))) {
        cli::cli_abort("Invalid BOOLEAN value in INLINE column {.val {column$name}}.")
      }
      ifelse(is.na(lower), NA, lower == "true")
    },
    DATE = as.Date(values, format = "%Y-%m-%d"),
    TIMESTAMP = db_sql_parse_inline_timestamp(values),
    BINARY = purrr::map(values, ~ if (is.na(.x)) NULL else base64enc::base64decode(.x)),
    values
  ))
  if (type %in% c("FLOAT", "DOUBLE", "DATE", "TIMESTAMP") &&
      any(!is.na(values) & is.na(decoded) & !is.nan(decoded))) {
    cli::cli_abort("Unable to decode INLINE column {.val {column$name}} as {.val {type}}.")
  }
  decoded
}

db_sql_parse_inline_timestamp <- function(values) {
  values <- sub(" ", "T", values, fixed = TRUE)
  values <- sub("Z$", "+0000", values)
  values <- sub("([+-][0-9]{2}):([0-9]{2})$", "\\1\\2", values)
  has_offset <- grepl("[+-][0-9]{4}$", values)
  values[!is.na(values) & !has_offset] <- paste0(values[!is.na(values) & !has_offset], "+0000")
  as.POSIXct(values, format = "%Y-%m-%dT%H:%M:%OS%z", tz = "UTC")
}

# Fetch only the INLINE chunks needed for the requested row count.
db_sql_fetch_inline <- function(resp, row_limit = NULL, host, token) {
  if (!is.null(row_limit) && (!is.numeric(row_limit) || length(row_limit) != 1L ||
      is.na(row_limit) || row_limit < 0 || (is.finite(row_limit) && row_limit != floor(row_limit)))) {
    cli::cli_abort("{.arg row_limit} must be a non-negative integer, {.val Inf}, or {.val NULL}.")
  }
  limit <- min(row_limit %||% Inf, resp$manifest$total_row_count %||% Inf)
  if (limit == 0) return(db_sql_process_inline(list(data_array = list()), resp$manifest))
  chunks <- list()
  result <- resp$result
  fetched <- 0
  seen <- numeric()
  repeat {
    index <- result$chunk_index %||% 0L
    if (index %in% seen) cli::cli_abort("INLINE result returned a repeated chunk index.")
    seen <- c(seen, index)
    count <- length(result$data_array)
    if (!is.null(result$row_offset) && result$row_offset != fetched) {
      cli::cli_abort("INLINE result chunk offset does not match the number of rows fetched.")
    }
    if (!is.null(result$row_count) && result$row_count != count) {
      cli::cli_abort("INLINE result chunk row count does not match its data.")
    }
    chunks[[length(chunks) + 1L]] <- db_sql_process_inline(result, resp$manifest, limit - fetched)
    fetched <- fetched + count
    if (fetched >= limit) break
    next_index <- result$next_chunk_index
    if (is.null(next_index)) {
      if (is.finite(limit) && fetched < limit) {
        cli::cli_abort("INLINE results ended before the expected {limit} rows; received {fetched}.")
      }
      break
    }
    if (next_index %in% seen) cli::cli_abort("INLINE result returned a repeated chunk index.")
    result <- db_sql_exec_result(resp$statement_id, chunk_index = next_index, host = host, token = token)
  }
  if (length(chunks) == 1L) return(chunks[[1]])
  columns <- purrr::map(seq_along(chunks[[1]]), function(i) {
    do.call(c, purrr::map(chunks, ~ .x[[i]]))
  })
  names(columns) <- names(chunks[[1]])
  tibble::new_tibble(columns, nrow = sum(purrr::map_int(chunks, nrow)))
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
#' @param resp Query status response from SQL execution
#' @param return_arrow Boolean, return arrow Table instead of tibble
#' @param max_active_connections Integer for concurrent downloads
#' @param fetch_timeout Integer, timeout in seconds for downloading each result chunk
#' @param row_limit Integer, limit number of rows returned and chunks downloaded
#' @param host Databricks host
#' @param token Databricks token
#' @param show_progress If `TRUE`, show progress updates during result fetching (default: `TRUE`)
#' @returns tibble or arrow Table with query results
#' @keywords internal
db_sql_fetch_results <- function(
  resp,
  return_arrow = FALSE,
  max_active_connections = 30,
  fetch_timeout = 300,
  row_limit = NULL,
  host = db_host(),
  token = db_token(),
  show_progress = TRUE
) {
  if (!is.null(row_limit) && (!is.numeric(row_limit) || length(row_limit) != 1L ||
      is.na(row_limit) || row_limit < 0 || (is.finite(row_limit) && row_limit != floor(row_limit)))) {
    cli::cli_abort("{.arg row_limit} must be a non-negative integer, {.val Inf}, or {.val NULL}.")
  }
  manifest <- resp$manifest
  if (isTRUE(row_limit == 0) || isTRUE(manifest$total_row_count == 0)) {
    result <- db_sql_create_empty_result(manifest)
    return(if (return_arrow && rlang::is_installed("arrow")) arrow::Table$create(result) else result)
  }
  statement_id <- resp$statement_id
  total_chunks <- manifest$total_chunk_count

  if (total_chunks == 1) {
    res <- db_sql_fetch_results_fast(
      resp = resp,
      statement_id = statement_id,
      manifest = manifest,
      return_arrow = return_arrow,
      fetch_timeout = fetch_timeout,
      row_limit = row_limit,
      host = host,
      token = token,
      show_progress = show_progress
    )
    return(res)
  }

  db_sql_fetch_results_parallel(
    statement_id = statement_id,
    manifest = manifest,
    last_chunk_index = total_chunks - 1L,
    return_arrow = return_arrow,
    max_active_connections = max_active_connections,
    fetch_timeout = fetch_timeout,
    row_limit = row_limit,
    host = host,
    token = token,
    show_progress = show_progress
  )
}

#' Fetch SQL Query Results (Fast Path)
#'
#' @keywords internal
db_sql_fetch_results_fast <- function(
  resp,
  statement_id,
  manifest,
  return_arrow = FALSE,
  fetch_timeout = 300,
  row_limit = NULL,
  host = db_host(),
  token = db_token(),
  show_progress = TRUE
) {
  db_sql_fetch_external_chunks(statement_id, manifest, 0L, return_arrow,
    1L, fetch_timeout, row_limit, host, token, show_progress, first_result = resp$result)
}

#' Fetch SQL Query Results (Parallel Path)
#'
#' @keywords internal
db_sql_fetch_results_parallel <- function(
  statement_id,
  manifest,
  last_chunk_index,
  return_arrow = FALSE,
  max_active_connections = 30,
  fetch_timeout = 300,
  row_limit = NULL,
  host = db_host(),
  token = db_token(),
  show_progress = TRUE
) {
  db_sql_fetch_external_chunks(statement_id, manifest, seq.int(0L, last_chunk_index),
    return_arrow, max_active_connections, fetch_timeout, row_limit, host, token, show_progress)
}

db_sql_fetch_external_chunks <- function(statement_id, manifest, indices,
  return_arrow, max_active_connections, fetch_timeout, row_limit, host, token,
  show_progress, first_result = NULL) {
  if (!is.numeric(max_active_connections) || length(max_active_connections) != 1L ||
      is.na(max_active_connections) || !is.finite(max_active_connections) ||
      max_active_connections < 1 || max_active_connections != floor(max_active_connections)) {
    cli::cli_abort("{.arg max_active_connections} must be a positive integer.")
  }
  limit <- min(row_limit %||% Inf, manifest$total_row_count %||% Inf)
  metadata <- manifest$chunks
  has_row_counts <- length(metadata) == length(indices) && length(metadata) > 0L &&
    all(purrr::map_lgl(metadata, ~ !is.null(.x$row_offset) && !is.null(.x$row_count)))
  if (has_row_counts) {
    metadata <- metadata[order(purrr::map_dbl(metadata, "row_offset"))]
    counts <- purrr::map_dbl(metadata, "row_count")
    offsets <- purrr::map_dbl(metadata, "row_offset")
    if (any(counts < 0) || any(offsets != c(0, head(cumsum(counts), -1L)))) {
      cli::cli_abort("External result chunk metadata contains overlapping or missing rows.")
    }
    metadata <- purrr::keep(metadata, ~ .x$row_offset < limit && .x$row_count > 0)
    indices <- purrr::map_int(metadata, "chunk_index")
  }
  batch_size <- if (has_row_counts || is.null(row_limit) || is.infinite(row_limit)) max_active_connections else 1L
  chunks <- list()
  fetched <- 0
  while (length(indices) > 0L && fetched < limit) {
    batch <- head(indices, batch_size)
    indices <- tail(indices, -length(batch))
    if (!is.null(first_result)) {
      links <- first_result$external_links
      expiration <- if (length(links) > 0L) links[[1]]$expiration else NULL
      if (!is.null(expiration)) {
        expires_at <- db_sql_parse_inline_timestamp(expiration)
        if (is.na(expires_at) || expires_at <= Sys.time()) first_result <- NULL
      }
    }
    if (is.null(first_result)) {
      results <- purrr::map(batch, db_sql_exec_result, statement_id = statement_id,
        host = host, token = token)
    } else {
      results <- list(first_result)
      first_result <- NULL
    }
    links <- purrr::map2(results, batch, function(result, index) {
      matching <- purrr::keep(result$external_links, ~ identical(as.integer(.x$chunk_index), as.integer(index)))
      if (length(matching) == 0L && length(result$external_links) == 1L &&
          is.null(result$external_links[[1]]$chunk_index)) matching <- result$external_links
      if (length(matching) != 1L) cli::cli_abort("Expected one external link for result chunk {index}.")
      link <- matching[[1]]
      expected <- purrr::detect(metadata, ~ .x$chunk_index == index)$row_count
      link$row_count <- link$row_count %||% expected
      if (!is.null(expected) && link$row_count != expected) {
        cli::cli_abort("External result chunk {index} row count does not match the manifest.")
      }
      link
    })
    decoded <- db_sql_download_external_batch(links, limit - fetched, return_arrow,
      max_active_connections, fetch_timeout, show_progress)
    chunks <- c(chunks, decoded)
    fetched <- fetched + sum(purrr::map_dbl(decoded, nrow))
  }
  if (is.finite(limit) && fetched < limit) {
    cli::cli_abort("External results ended before the expected {limit} rows; received {fetched}.")
  }
  if (length(chunks) == 0L) return(db_sql_create_empty_result(manifest))
  if (length(chunks) == 1L) return(chunks[[1]])
  if (inherits(chunks[[1]], "Table")) do.call(arrow::concat_tables, chunks) else purrr::list_rbind(chunks)
}

db_sql_download_external_batch <- function(links, row_limit, return_arrow,
  max_active_connections, fetch_timeout, show_progress) {
  directory <- fs::file_temp("brickster-results-")
  fs::dir_create(directory)
  on.exit(fs::dir_delete(directory), add = TRUE)
  paths <- fs::path(directory, paste0(seq_along(links), ".arrow"))
  reqs <- purrr::map(links, function(link) {
    req <- httr2::request(link$external_link) |>
      httr2::req_retry(max_tries = 3, backoff = ~1)
    if (!is.null(fetch_timeout)) req <- httr2::req_timeout(req, fetch_timeout)
    req
  })
  httr2::req_perform_parallel(reqs, paths = paths, max_active = max_active_connections,
    progress = show_progress)
  remaining <- new.env(parent = emptyenv())
  remaining$rows <- row_limit
  purrr::map2(paths, links, function(path, link) {
    if (rlang::is_installed("arrow")) {
      result <- arrow::read_ipc_stream(path, as_data_frame = FALSE)
      if (!is.null(link$row_count) && nrow(result) != link$row_count) {
        cli::cli_abort("Downloaded result chunk row count does not match its metadata.")
      }
      count <- min(nrow(result), remaining$rows)
      result <- result$Slice(0, count)
      if (!return_arrow) result <- tibble::as_tibble(result)
    } else {
      result <- tibble::as_tibble(nanoarrow::read_nanoarrow(path))
      if (!is.null(link$row_count) && nrow(result) != link$row_count) {
        cli::cli_abort("Downloaded result chunk row count does not match its metadata.")
      }
      count <- min(nrow(result), remaining$rows)
      result <- head(result, count)
    }
    remaining$rows <- remaining$rows - count
    result
  })
}


#' Execute query with SQL Warehouse
#'
#' @inheritParams db_sql_exec_query
#' @param return_arrow Boolean, return an [arrow::Table] instead of a
#' [tibble::tibble] for EXTERNAL_LINKS results. INLINE results always return a tibble.
#' @param max_active_connections Integer to decide on concurrent downloads.
#' @param fetch_timeout Integer, timeout in seconds for downloading each result chunk
#' @param disposition Disposition mode ("INLINE" or "EXTERNAL_LINKS")
#' @param show_progress If `TRUE`, show progress updates during query execution (default: `TRUE`)
#' @details
#' INLINE results follow continuation chunks up to `row_limit`. Values are decoded
#' from the manifest: BYTE/SHORT/INT to integer, FLOAT/DOUBLE to numeric, BOOLEAN
#' to logical, DATE to Date, and TIMESTAMP to POSIXct in UTC. INT columns containing
#' -2147483648 use numeric vectors because R reserves that integer for `NA`.
#' BINARY columns are lists of raw vectors, with `NULL` for SQL nulls and `raw(0)`
#' for empty values. LONG (BIGINT) and DECIMAL remain character to avoid precision
#' loss; complex types and timestamps without time zones also remain character.
#' SQL nulls become typed missing values. Empty results use the same type rules.
#'
#' EXTERNAL_LINKS downloads use temporary files in batches of at most
#' `max_active_connections` chunks. Manifest row offsets select the chunks needed
#' for `row_limit`; without those offsets, limited reads fetch one chunk at a time.
#' The last required chunk is downloaded in full, then sliced before conversion
#' to an R data frame when Arrow is available. Temporary files are removed after
#' each batch, including on errors. The returned result still requires memory
#' proportional to the requested rows.
#' @returns [tibble::tibble] for INLINE results; [tibble::tibble] or [arrow::Table]
#'   for EXTERNAL_LINKS results, according to `return_arrow`.
#' @export
db_sql_query <- function(
  warehouse_id,
  statement,
  schema = NULL,
  catalog = NULL,
  parameters = NULL,
  row_limit = NULL,
  byte_limit = NULL,
  wait_timeout = "5s",
  return_arrow = FALSE,
  max_active_connections = 30,
  fetch_timeout = 300,
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
    wait_timeout = wait_timeout,
    disposition = disposition,
    format = format,
    host = host,
    token = token,
    show_progress = show_progress
  )

  # Check for empty results early and return immediately
  # Use total_row_count to detect empty result sets
  if (resp$manifest$total_row_count == 0 && disposition != "INLINE") {
    return(db_sql_create_empty_result(resp$manifest))
  }

  # Fetch and process results based on disposition
  if (disposition == "INLINE") {
    # Use inline processor for JSON_ARRAY results
    db_sql_fetch_inline(resp, row_limit = row_limit, host = host, token = token)
  } else {
    # Use external links processor for ARROW_STREAM results
    db_sql_fetch_results(
      resp = resp,
      return_arrow = return_arrow,
      max_active_connections = max_active_connections,
      fetch_timeout = fetch_timeout,
      row_limit = row_limit,
      host = host,
      token = token,
      show_progress = show_progress
    )
  }
}
