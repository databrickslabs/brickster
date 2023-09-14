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
      # uncomment when available via cran
      # httr2::req_progress(type = "down") %>%
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
#' @param contents String that is base64 encoded.
#' @param overwrite Flag (Default: `FALSE`) that specifies whether to overwrite
#' existing files.
#' @inheritParams db_volume_read
#' @inheritParams auth_params
#'
#' @details
#' Either `contents` or `file` must be specified. `file` takes precedent over
#' `contents` if both are specified.
#'
#' Uploads a file of up to 2 GiB.
#'
#' @family Volumes FileSystem API
#'
#' @export
db_volume_write <- function(path, file = NULL, contents = NULL, overwrite = FALSE,
                        host = db_host(), token = db_token()) {

  body <- list(
    path = path,
    overwrite = ifelse(overwrite, "true", "false")
  )

  # file takes priority, so don't bother if file is also specified
  if (!is.null(contents) && is.null(file)) {
    # contents must be base64 encoded string
    body$contents <- base64enc::base64encode(base::charToRaw(contents))
  } else if (!is.null(file)) {
    body$contents <- curl::form_file(path = file)
  } else {
    stop(cli::format_error(c(
      "Nothing to upload:",
      "x" = "Either `file` or `contents` must be specified."
    )))
  }

  req <- db_request(
    endpoint = paste0("fs/files/", path),
    method = "PUT",
    version = "2.0",
    host = host,
    token = token
  )

  req %>%
    httr2::req_body_multipart(
      path = body$path,
      contents = body$contents,
      overwrite = body$overwrite
    ) %>%
    httr2::req_error(body = db_req_error_body) %>%
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
