#' Volume FileSystem Read
#'
#' Return the contents of a file within a volume (up to 2GiB).
#'
#' @param path Absolute path of the file in the Files API, omitting the initial
#' slash.
#' @param destination Path to write downloaded file to.
#' @inheritParams db_dbfs_create
#' @inheritParams db_sql_warehouse_create
#'
#' @family Volumes FileSystem API
#'
#' @export
db_volume_read <- function(path, destination,
                           host = db_host(), token = db_token(),
                           perform_request = TRUE) {

  req <- db_request(
    endpoint = paste0("fs/files/", path),
    method = "GET",
    version = "2.0",
    host = host,
    token = token
  )

  if (perform_request) {
    req %>%
      httr2::req_error(body = db_req_error_body) %>%
      httr2::req_progress(type = "down") %>%
      httr2::req_perform(path = destination) %>%
      httr2::resp_check_status()
  } else {
    req
  }

  return(destination)

}

#' Volume FileSystem Delete
#'
#' @inheritParams auth_params
#' @inheritParams db_volume_read
#' @inheritParams db_sql_warehouse_create
#'
#' @family Volumes FileSystem API
#'
#' @export
db_volume_delete <- function(path,
                           host = db_host(), token = db_token(),
                           perform_request = TRUE) {

  req <- db_request(
    endpoint = paste0("fs/files/", path),
    method = "DELETE",
    version = "2.0",
    host = host,
    token = token
  )

  if (perform_request) {
    req %>%
      httr2::req_error(body = db_req_error_body) %>%
      httr2::req_perform() %>%
      httr2::resp_check_status()
  } else {
    req
  }

}

#' Volume FileSystem Write
#'
#' Upload a file to volume filesystem.
#'
#' @param file Path to a file on local system, takes precedent over `path`.
#' @param overwrite Flag (Default: `FALSE`) that specifies whether to overwrite
#' existing files.
#' @inheritParams db_volume_read
#' @inheritParams auth_params
#'
#' @details
#' Uploads a file of up to 5 GiB.
#'
#' @family Volumes FileSystem API
#'
#' @export
db_volume_write <- function(path, file = NULL, overwrite = FALSE,
                        host = db_host(), token = db_token(), perform_request = TRUE) {

  if (is.null(file)) {
    stop(cli::format_error(c(
      "Nothing to upload:",
      "x" = "Either `file` must be specified."
    )))
  }

  req <- db_request(
    endpoint = paste0("fs/files/", path),
    method = "PUT",
    version = "2.0",
    host = host,
    token = token
  )

  req <- req %>%
    httr2::req_url_query(
      overwrite = ifelse(overwrite, "true", "false")
    )

  req %>%
    httr2::req_body_file(file) %>%
    httr2::req_error(body = db_req_error_body) %>%
    httr2::req_progress(type = "up") %>%
    httr2::req_perform() %>%
    httr2::resp_check_status()

}


#' Volume FileSystem File Status

#' @inheritParams db_volume_read
#' @inheritParams auth_params
#' @inheritParams db_dbfs_create
#' @inheritParams db_sql_warehouse_create
#'
#' @family Volumes FileSystem API
#'
#' @export
db_volume_file_exists <- function(path,
                             host = db_host(), token = db_token(),
                             perform_request = TRUE) {

  req <- db_request(
    endpoint = paste0("fs/files/", path),
    method = "HEAD",
    version = "2.0",
    host = host,
    token = token
  )

  if (perform_request) {
    status <- req %>%
      httr2::req_error(is_error = function(resp) httr2::resp_status(resp) == 500) %>%
      httr2::req_perform() %>%
      httr2::resp_status()

    return(status == 200)

  } else {
    req
  }

}
