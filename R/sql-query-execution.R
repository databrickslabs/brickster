# https://docs.databricks.com/api/workspace/statementexecution
# https://docs.databricks.com/en/sql/admin/sql-execution-tutorial.html#language-curl

#' Execute SQL Query
#'
#' @details TODO
#'
#' @param statement TODO
#' @param warehouse_id TODO
#' @param catalog TODO
#' @param schema TODO
#' @param parameters TODO
#' @param row_limit TODO
#' @param byte_limit TODO
#' @param disposition TODO
#' @param format TODO
#' @param wait_timeout TODO
#' @inheritParams auth_params
#'
#' @family SQL Execution APIs
#'
#' @export
db_sql_exec_query <- function(statement, warehouse_id,
                         catalog = NULL, schema = NULL, parameters = NULL,
                         row_limit = NULL, byte_limit = NULL,
                         disposition = c("INLINE", "EXTERNAL_LINKS"),
                         format = c("JSON_ARRAY", "ARROW_STREAM", "CSV"),
                         wait_timeout = "10s",
                         on_wait_timeout = c("CONTINUE", "CANCEL"),
                         host = db_host(), token = db_token(),
                         perform_request = TRUE) {

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
#' @details TODO
#'
#' @param statement_id TODO
#' @inheritParams auth_params
#'
#' @family SQL Execution APIs
#'
#' @export
db_sql_exec_cancel <- function(statement_id,
                          host = db_host(), token = db_token(),
                          perform_request = TRUE) {

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
#' @details TODO
#'
#' @param statement_id TODO
#' @inheritParams auth_params
#'
#' @family SQL Execution APIs
#'
#' @export
db_sql_exec_status <- function(statement_id,
                          host = db_host(), token = db_token(),
                          perform_request = TRUE) {

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
#' @details TODO
#'
#' @param statement_id TODO
#' @param chunk_index TODO
#' @inheritParams auth_params
#'
#' @family SQL Execution APIs
#'
#' @export
db_sql_exec_result <- function(statement_id, chunk_index,
                          host = db_host(), token = db_token(),
                          perform_request = TRUE) {

  req <- db_request(
    endpoint = paste0("sql/statements/", statement_id, "/result/chunks/", chunk_index),
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

