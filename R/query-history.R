# https://docs.databricks.com/sql/api/query-history.html

#' List Warehouse Query History
#'
#' For more details refer to the [query history documentation](https://docs.databricks.com/sql/api/query-history.html#list).
#' This function elevates the sub-components of `filter_by` parameter to the R
#' function directly.
#'
#' By default the filter parameters `statuses`, `user_ids`, and `endpoints_ids`
#' are `NULL`.
#'
#' @param statuses Allows filtering by query status. Possible values are:
#' `QUEUED`, `RUNNING`, `CANCELED`, `FAILED`, `FINISHED`. Multiple permitted.
#' @param user_ids Allows filtering by user ID's. Multiple permitted.
#' @param endpoint_ids Allows filtering by endpoint ID's. Multiple permitted.
#' @param start_time_ms Integer, limit results to queries that started after this time.
#' @param end_time_ms Integer, limit results to queries that started before this time.
#' @param max_results Limit the number of results returned in one page. Default is 100.
#' @param page_token Opaque token used to get the next page of results. Optional.
#' @param include_metrics Whether to include metrics about query execution.
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @family SQL Query History API
#'
#' @export
db_sql_query_history <- function(statuses = NULL,
                                 user_ids = NULL,
                                 endpoint_ids = NULL,
                                 start_time_ms = NULL,
                                 end_time_ms = NULL,
                                 max_results = 100,
                                 page_token = NULL,
                                 include_metrics = FALSE,
                                 host = db_host(), token = db_token(),
                                 perform_request = TRUE) {
  status_options <- c("QUEUED", "RUNNING", "CANCELED", "FAILED", "FINISHED")
  if (!is.null(statuses)) {
    statuses <- match.arg(statuses, choices = status_options, several.ok = TRUE)
  }

  # rather than require a data structure keep these as function level inputs
  filter_by <- list()

  if (!is.null(statuses)) {
    filter_by$statuses <- statuses
  }
  if (!is.null(user_ids)) {
    filter_by$user_ids <- user_ids
  }
  if (!is.null(endpoint_ids)) {
    filter_by$endpoint_ids <- endpoint_ids
  }
  if (!(is.null(start_time_ms) && is.null(end_time_ms))) {
    filter_by$query_start_time_range <- list(
      start_time_ms = start_time_ms,
      end_time_ms = end_time_ms
    )
  }

  if (length(filter_by) == 0) {
    filter_by <- NULL
  }

  body <- list(
    filter_by = filter_by,
    max_results = max_results,
    page_token = page_token,
    include_metrics = include_metrics
  )

  req <- db_request(
    endpoint = "sql/history/queries",
    method = "GET",
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
