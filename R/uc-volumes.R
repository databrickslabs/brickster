#' List Volumes (Unity Catalog)
#'
#' @param catalog Parent catalog of volume
#' @param schema Parent schema of volume
#' @param max_results Maximum number of volumes to return (default: 10000).
#' @param include_browse Whether to include volumes in the response for which
#' the principal can only access selective metadata for.
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#' @inheritParams db_sql_query_history
#'
#' @family Unity Catalog Volume Management
#'
#' @returns List
#' @export
db_uc_volumes_list <- function(catalog, schema,
                               max_results = 10000,
                               include_browse = TRUE,
                               page_token = NULL,
                               host = db_host(), token = db_token(),
                               perform_request = TRUE) {

  req <- db_request(
    endpoint = "unity-catalog/volumes",
    method = "GET",
    version = "2.1",
    host = host,
    token = token
  ) |>
    httr2::req_url_query(
      catalog_name = catalog,
      schema_name = schema
    )

  if (perform_request) {
    db_perform_request(req)$volumes
  } else {
    req
  }
}



#' Get Volume (Unity Catalog)
#'

#' @param volume Volume name.
#' @inheritParams db_uc_volumes_list
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @family Unity Catalog Volume Management
#'
#' @returns List
#' @export
db_uc_volumes_get <- function(catalog, schema, volume,
                             include_browse = TRUE,
                             host = db_host(), token = db_token(),
                             perform_request = TRUE) {

  body <- list(
    include_browse = from_logical(include_browse)
  )

  req <- db_request(
    endpoint = "unity-catalog/volumes",
    method = "GET",
    version = "2.1",
    host = host,
    token = token,
    body = body
  ) |>
    httr2::req_url_path_append(paste(catalog, schema, volume, sep = "."))

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }
}


#' Delete Volume (Unity Catalog)
#'
#' @inheritParams db_uc_volumes_list
#' @inheritParams db_uc_volumes_get
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @family Unity Catalog Volume Management
#'
#' @returns Boolean
#' @export
db_uc_volumes_delete <- function(catalog, schema, volume,
                                host = db_host(), token = db_token(),
                                perform_request = TRUE) {

  req <- db_request(
    endpoint = "unity-catalog/volumes",
    method = "DELETE",
    version = "2.1",
    host = host,
    token = token
  ) |>
    httr2::req_url_path_append(paste(catalog, schema, volume, sep = "."))

  if (perform_request) {
    db_perform_request(req)
    TRUE
  } else {
    req
  }
}


#' Update Volume (Unity Catalog)
#'
#' @param owner The identifier of the user who owns the volume (Optional).
#' @param comment The comment attached to the volume (Optional).
#' @param new_name New name for the volume (Optional).
#' @inheritParams db_uc_volumes_list
#' @inheritParams db_uc_volumes_get
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @family Unity Catalog Volume Management
#'
#' @returns List
#' @export
db_uc_volumes_update <- function(catalog, schema, volume,
                              owner = NULL,
                              comment = NULL,
                              new_name = NULL,
                              host = db_host(), token = db_token(),
                              perform_request = TRUE) {

  body <- list(
    owner = owner,
    comment = comment,
    new_name = new_name
  )

  req <- db_request(
    endpoint = "unity-catalog/volumes",
    method = "PATCH",
    version = "2.1",
    host = host,
    token = token,
    body = body
  ) |>
    httr2::req_url_path_append(paste(catalog, schema, volume, sep = "."))

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }
}


#' Update Volume (Unity Catalog)
#'
#' @param volume_type Either `'MANAGED'` or `'EXTERNAL'`.
#' @param storage_location The storage location on the cloud, only specified
#' when `volume_type` is `'EXTERNAL'`.
#' @param comment The comment attached to the volume.
#' @inheritParams db_uc_volumes_list
#' @inheritParams db_uc_volumes_get
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @family Unity Catalog Volume Management
#'
#' @returns List
#' @export
db_uc_volumes_create <- function(catalog, schema, volume,
                                 volume_type = c("MANAGED", "EXTERNAL"),
                                 storage_location = NULL,
                                 comment = NULL,
                                 host = db_host(), token = db_token(),
                                 perform_request = TRUE) {

  volume_type <- match.arg(volume_type)
  if (!is.null(storage_location) && volume_type == "MANAGED") {
    cli::cli_abort("Managed volumes require `storage_location` to be `NULL`")
  }

  body <- list(
    catalog_name = catalog,
    schema_name = schema,
    name = volume,
    volume_type = volume_type,
    storage_location = storage_location,
    comment = comment
  )

  req <- db_request(
    endpoint = "unity-catalog/volumes",
    method = "POST",
    version = "2.1",
    host = host,
    token = token,
    body = body
  )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }
}



