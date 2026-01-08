#' List SQL Queries
#'
#' @details Gets a list of queries accessible to the user, ordered by creation
#' time. Warning: Calling this API concurrently 10 or more times could result
#' in throttling, service degradation, or a temporary ban.
#'
#' @param page_size Integer, number of results to return for each request.
#' @param page_token Token used to get the next page of results. If not
#' specified, returns the first page of results as well as a next page token if
#' there are more results.
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @family SQL Queries API
#'
#' @export
db_query_list <- function(
  page_size = 20,
  page_token = NULL,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  body <- list(
    page_size = page_size,
    page_token = page_token
  )

  req <- db_request(
    endpoint = "sql/queries",
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

#' Create a SQL Query
#'
#' @param warehouse_id description
#' @param query_text Text of the query to be run.
#' @param display_name Display name of the query that appears in list views,
#' widget headings, and on the query page.
#' @param description General description that conveys additional information
#' about this query such as usage notes.
#' @param catalog Name of the catalog where this query will be executed.
#' @param schema Name of the schema where this query will be executed.
#' @param parent_path Workspace path of the workspace folder containing the object.
#' @param run_as_mode Sets the "Run as" role for the object.
#' @param apply_auto_limit Whether to apply a 1000 row limit to the query result.
#' @param auto_resolve_display_name Automatically resolve query display name
#' conflicts. Otherwise, fail the request if the query's display name conflicts
#' with an existing query's display name.
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @family SQL Queries API
#'
#' @export
db_query_create <- function(
  warehouse_id,
  query_text,
  display_name,
  description = NULL,
  catalog = NULL,
  schema = NULL,
  parent_path = NULL,
  run_as_mode = c("OWNER", "VIEWER"),
  apply_auto_limit = FALSE,
  auto_resolve_display_name = TRUE,
  tags = list(),
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  run_as_mode <- match.arg(run_as_mode)
  body <- list(
    query = list(
      warehouse_id = warehouse_id,
      query_text = query_text,
      display_name = display_name,
      description = description,
      catalog = catalog,
      schema = schema,
      parent_path = parent_path,
      run_as_mode = run_as_mode,
      tags = tags,
      apply_auto_limit = apply_auto_limit
    ),
    auto_resolve_display_name = auto_resolve_display_name
  )

  req <- db_request(
    endpoint = "sql/queries",
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

#' Get a SQL Query
#'
#' Returns the repo with the given repo ID.
#'
#' @param id String, ID for the query.
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @family SQL Queries API
#'
#' @export
db_query_get <- function(
  id,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  req <- db_request(
    endpoint = paste0("sql/queries/", id),
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

#' Update a SQL Query
#'
#' @param id Query id
#' @inheritParams auth_params
#' @inheritParams db_query_create
#' @inheritParams db_sql_warehouse_create
#'
#' @family SQL Queries API
#'
#' @export
db_query_update <- function(
  id,
  warehouse_id = NULL,
  query_text = NULL,
  display_name = NULL,
  description = NULL,
  catalog = NULL,
  schema = NULL,
  parent_path = NULL,
  run_as_mode = NULL,
  apply_auto_limit = NULL,
  auto_resolve_display_name = NULL,
  tags = NULL,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  run_as_mode <- match.arg(run_as_mode)
  body <- list(auto_resolve_display_name = auto_resolve_display_name)
  query <- list(
    warehouse_id = warehouse_id,
    query_text = query_text,
    display_name = display_name,
    description = description,
    catalog = catalog,
    schema = schema,
    parent_path = parent_path,
    run_as_mode = run_as_mode,
    apply_auto_limit = apply_auto_limit,
    tags = tags
  )
  # keep non-null values
  body$query <- Filter(length, query)
  # dynamically generate update mask
  body$update_mask <- paste(names(body$query), collapse = ",")

  req <- db_request(
    endpoint = paste0("sql/queries/", id),
    method = "PATCH",
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

#' Delete a SQL Query
#'
#' @details Moves a query to the trash. Trashed queries immediately disappear
#' from searches and list views, and cannot be used for alerts. You can restore
#' a trashed query through the UI. A trashed query is permanently deleted after
#' 30 days.
#'
#' @inheritParams db_query_get
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @family SQL Queries API
#'
#' @export
db_query_delete <- function(
  id,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  req <- db_request(
    endpoint = paste0("sql/queries/", id),
    method = "DELETE",
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
