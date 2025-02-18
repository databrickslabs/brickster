#' List Catalogs (Unity Catalog)
#'
#' @param max_results Maximum number of catalogs to return (default: 1000).
#' @param include_browse Whether to include catalogs in the response for which
#' the principal can only access selective metadata for.
#' @inheritParams auth_params
#' @inheritParams db_sql_query_history
#' @inheritParams db_sql_warehouse_create
#'
#' @family Unity Catalog Management
#'
#' @returns List
#' @export
db_uc_catalogs_list <- function(max_results = 1000,
                                include_browse = TRUE,
                                page_token = NULL,
                                host = db_host(), token = db_token(),
                                perform_request = TRUE) {

  stopifnot(max_results <= 1000)

  body <- list(
    max_results = max_results,
    include_browse = include_browse,
    page_token = page_token
  )

  req <- db_request(
    endpoint = "unity-catalog/catalogs",
    method = "GET",
    version = "2.1",
    host = host,
    token = token,
    body = body
  )

  if (perform_request) {
    db_perform_request(req)$catalogs
  } else {
    req
  }
}


#' Get Catalog (Unity Catalog)
#'
#' @param catalog The name of the catalog.
#' @inheritParams auth_params
#' @inheritParams db_sql_query_history
#' @inheritParams db_sql_warehouse_create
#'
#' @family Unity Catalog Management
#'
#' @returns List
#' @export
db_uc_catalogs_get <- function(catalog,
                               host = db_host(), token = db_token(),
                               perform_request = TRUE) {

  req <- db_request(
    endpoint = "unity-catalog/catalogs/",
    method = "GET",
    version = "2.1",
    host = host,
    token = token
  ) |>
    httr2::req_url_path_append(catalog)

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }
}
