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
    } else if (
      status$status$status$state %in% c("FAILED", "CLOSED", "CANCELED")
    ) {
      stop(paste0("queries status: ", status$status$state))
    }
  }

  status
}


# TODO:
# - add mode for when no arrow present (use nanoarrow?)
# - add verbose mode?

#' Execute query with SQL Warehouse
#'
#' @inheritParams db_sql_exec_query
#' @param return_arrow Boolean, determine if result is [tibble::tibble] or
#' [arrow::Table].
#' @param max_active_connections Integer to decide on concurrent downloads.
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
  host = db_host(),
  token = db_token()
) {
  resp <- db_sql_exec_query(
    warehouse_id = warehouse_id,
    statement = statement,
    disposition = "EXTERNAL_LINKS",
    format = "ARROW_STREAM",
    wait_timeout = "30s",
    on_wait_timeout = "CONTINUE",
    schema = schema,
    catalog = catalog,
    parameters = parameters,
    row_limit = row_limit,
    byte_limit = byte_limit,
    host = host,
    token = token
  )

  # if query doesn't finish within 30s, continue to poll for completion
  if (resp$status$state %in% c("RUNNING", "PENDING")) {
    resp <- db_sql_exec_poll_for_success(resp$statement_id)
  }

  # fetch all external links
  total_chunks <- resp$manifest$total_chunk_count - 1
  total_rows <- resp$manifest$total_row_count

  # NOTE: theoretically can skip getting the first since its part of resp object
  # not doing that to make code slightly easier
  reqs <- purrr::map(
    .x = seq.int(total_chunks, from = 0),
    .f = db_sql_exec_result,
    statement_id = resp$statement_id,
    perform = FALSE
  )

  # do not respect `max_active_connections` at this stage
  # use low parallelism to get links
  resps <- httr2::req_perform_parallel(reqs, max_active = 3, progress = FALSE)

  links <- resps |>
    purrr::map(httr2::resp_body_json) |>
    purrr::map_chr(~ .x$external_links[[1]]$external_link) |>
    purrr::map(
      ~ httr2::request(.x) |>
        httr2::req_retry(max_tries = 3, backoff = ~1)
    )

  # download arrow stream data
  ipc_data <- httr2::req_perform_parallel(
    links,
    max_active = max_active_connections,
    progress = FALSE
  )

  # if arrow isn't available fallback to nanoarrow (much slower!)
  if (rlang::is_installed("arrow")) {
    # read ipc data as arrow table
    arrow_tbls <- ipc_data |>
      purrr::map(
        ~ arrow::read_ipc_stream(
          httr2::resp_body_raw(.x),
          as_data_frame = FALSE
        )
      )
    arrow_tbl <- do.call(arrow::concat_tables, arrow_tbls)
  } else {
    purrr::map(~ tibble::as_tibble(nanoarrow::read_nanoarrow(x))) |>
      purrr::list_rbind()
  }
}


if (return_arrow) {
  arrow_tbl
} else {
  tibble::as_tibble(arrow_tbl)
}
