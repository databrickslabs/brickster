#' List Tables (Unity Catalog)
#'
#' @param catalog Name of parent catalog for tables of interest.
#' @param schema Parent schema of tables.
#' @param max_results Maximum number of tables to return (default: 50, max: 50).
#' @param include_delta_metadata Whether delta metadata should be included in
#' the response.
#' @param omit_columns Whether to omit the columns of the table from the
#' response or not.
#' @param omit_properties Whether to omit the properties of the table from the
#' response or not.
#' @param omit_username Whether to omit the username of the table (e.g. owner,
#' updated_by, created_by) from the response or not.
#' @param include_browse Whether to include tables in the response for which the
#' principal can only access selective metadata for.
#' @param include_manifest_capabilities Whether to include a manifest containing
#' capabilities the table has.
#' @inheritParams auth_params
#' @inheritParams db_sql_query_history
#' @inheritParams db_sql_warehouse_create
#'
#' @returns List
#' @export
db_uc_tables_list <- function(catalog, schema, max_results = 50,
                              omit_columns = TRUE,
                              omit_properties = TRUE,
                              omit_username = TRUE,
                              include_browse = TRUE,
                              include_delta_metadata = FALSE,
                              include_manifest_capabilities = FALSE,
                              page_token = NULL,
                              host = db_host(), token = db_token(),
                              perform_request = TRUE) {

  stopifnot(max_results <= 50)

  req <- db_request(
    endpoint = "unity-catalog/tables",
    method = "GET",
    version = "2.1",
    host = host,
    token = token
  ) |>
    httr2::req_url_query(
      catalog_name = catalog,
      schema_name = schema,
      include_delta_metadata = from_logical(include_delta_metadata),
      omit_columns = from_logical(omit_columns),
      omit_properties = from_logical(omit_properties),
      omit_username = from_logical(omit_username),
      include_browse = from_logical(include_browse),
      include_manifest_capabilities = from_logical(include_manifest_capabilities),
      page_token = page_token
    )

  if (perform_request) {
    db_perform_request(req)$tables
  } else {
    req
  }
}

#' Get Table (Unity Catalog)
#'
#' @param catalog Parent catalog of table.
#' @param schema Parent schema of table.
#' @param table Table name.
#' @inheritParams db_uc_tables_list
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @returns List
#' @export
db_uc_tables_get <- function(catalog, schema, table,
                             omit_columns = TRUE,
                             omit_properties = TRUE,
                             omit_username = TRUE,
                             include_browse = TRUE,
                             include_delta_metadata = TRUE,
                             include_manifest_capabilities = FALSE,
                             host = db_host(), token = db_token(),
                             perform_request = TRUE) {

  body <- list(
    include_delta_metadata = from_logical(include_delta_metadata),
    omit_columns = from_logical(omit_columns),
    omit_properties = from_logical(omit_properties),
    omit_username = from_logical(omit_username),
    include_browse = from_logical(include_browse),
    include_manifest_capabilities = from_logical(include_manifest_capabilities)
  )

  req <- db_request(
    endpoint = "unity-catalog/tables",
    method = "GET",
    version = "2.1",
    host = host,
    token = token,
    body = body
  ) |>
    httr2::req_url_path_append(paste(catalog, schema, table, sep = "."))

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }
}

#' Delete Table (Unity Catalog)
#'
#' @inheritParams db_uc_tables_get
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @returns Boolean
#' @export
db_uc_tables_delete <- function(catalog, schema, table,
                                host = db_host(), token = db_token(),
                                perform_request = TRUE) {

  req <- db_request(
    endpoint = "unity-catalog/tables",
    method = "DELETE",
    version = "2.1",
    host = host,
    token = token
  ) |>
    httr2::req_url_path_append(paste(catalog, schema, table, sep = "."))

  if (perform_request) {
    db_perform_request(req)
    TRUE
  } else {
    req
  }
}

#' Check Table Exists (Unity Catalog)
#'
#' @inheritParams db_uc_tables_get
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @returns List with fields `table_exists` and `supports_foreign_metadata_update`
#' @export
db_uc_tables_exists <- function(catalog, schema, table,
                                host = db_host(), token = db_token(),
                                perform_request = TRUE) {

  req <- db_request(
    endpoint = "unity-catalog/tables",
    method = "GET",
    version = "2.1",
    host = host,
    token = token
  ) |>
    httr2::req_url_path_append(paste(catalog, schema, table, sep = ".")) |>
    httr2::req_url_path_append("exists")

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }
}


#' List Table Summaries (Unity Catalog)
#'
#' @param catalog Name of parent catalog for tables of interest.
#' @param schema_name_pattern A sql `LIKE` pattern (`%` and `_`) for schema
#' names. All schemas will be returned if not set or empty.
#' @param table_name_pattern A sql `LIKE` pattern (`%` and `_`) for table names.
#' All tables will be returned if not set or empty.
#' @param max_results Maximum number of summaries for tables to return
#' (default: 10000, max: 10000). If not set, the page length is set to a server
#' configured value.
#' @inheritParams db_sql_query_history
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#' @inheritParams db_uc_tables_list
#'
#' @returns List
#' @export
db_uc_tables_summaries <- function(catalog,
                                  schema_name_pattern = NULL,
                                  table_name_pattern = NULL,
                                  max_results = 10000,
                                  include_manifest_capabilities = FALSE,
                                  page_token = NULL,
                                  host = db_host(), token = db_token(),
                                  perform_request = TRUE) {

  stopifnot(max_results <= 10000)

  body <- list(
    catalog_name = catalog,
    schema_name_pattern = schema_name_pattern,
    table_name_pattern = table_name_pattern,
    max_results = max_results,
    include_manifest_capabilities = from_logical(include_manifest_capabilities),
    page_token = page_token
  )

  req <- db_request(
    endpoint = "unity-catalog/table-summaries",
    method = "GET",
    version = "2.1",
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

