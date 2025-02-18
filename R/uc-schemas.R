#' List Schemas (Unity Catalog)
#'
#' @param catalog Parent catalog for schemas of interest.
#' @param max_results Maximum number of schemas to return (default: 1000).
#' @inheritParams auth_params
#' @inheritParams db_sql_query_history
#' @inheritParams db_sql_warehouse_create
#'
#' @family Unity Catalog Management
#'
#' @returns List
#' @export
db_uc_schemas_list <- function(catalog,
                               max_results = 1000,
                               page_token = NULL,
                               host = db_host(), token = db_token(),
                               perform_request = TRUE) {

  stopifnot(max_results <= 1000)

  body <- list(
    max_results = max_results,
    page_token = page_token
  )

  req <- db_request(
    endpoint = "unity-catalog/schemas",
    method = "GET",
    version = "2.1",
    host = host,
    token = token,
    body = body
  ) |>
    httr2::req_url_query(catalog_name = catalog)

  if (perform_request) {
    db_perform_request(req)$schemas
  } else {
    req
  }
}


#' Get Schema (Unity Catalog)
#'
#' @param catalog Parent catalog for schema of interest.
#' @param schema Schema of interest.
#' @inheritParams auth_params
#' @inheritParams db_sql_query_history
#'
#' @family Unity Catalog Management
#'
#' @returns List
#' @export
db_uc_schemas_get <- function(catalog, schema,
                              include_browse = TRUE,
                              host = db_host(), token = db_token(),
                              perform_request = TRUE) {

  body <- list(
    include_browse = include_browse
  )

  req <- db_request(
    endpoint = "unity-catalog/schemas/",
    method = "GET",
    version = "2.1",
    host = host,
    token = token,
    body = body
  ) |>
    httr2::req_url_path_append(paste(catalog, schema, sep = "."))

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }
}

