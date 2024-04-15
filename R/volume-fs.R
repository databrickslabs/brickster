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

  db_volume_action(
    path = path,
    destination = destination,
    action = "GET",
    type = "files",
    host = host,
    token = token,
    perform_request = perform_request
  )

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

  db_volume_action(
    path = path,
    action = "DELETE",
    type = "directories",
    host = host,
    token = token,
    perform_request = perform_request
  )

}

#' Volume FileSystem List Directory Contents
#'
#' @inheritParams auth_params
#' @inheritParams db_volume_read
#' @inheritParams db_sql_warehouse_create
#'
#' @family Volumes FileSystem API
#'
#' @export
db_volume_list <- function(path,
                           host = db_host(), token = db_token(),
                           perform_request = TRUE) {

  # TODO: paginate automatically

  db_volume_action(
    path = path,
    action = "GET",
    type = "directories",
    host = host,
    token = token,
    perform_request = perform_request
  )

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
      "x" = "`file` must be specified."
    )))
  }

  db_volume_action(
    path = path,
    file = file,
    overwrite = overwrite,
    action = "PUT",
    type = "files",
    host = host,
    token = token,
    perform_request = perform_request
  )

}


#' Volume FileSystem File Status
#'
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

  db_volume_action(
    path = path,
    file = file,
    action = "HEAD",
    type = "files",
    host = host,
    token = token,
    perform_request = perform_request
  )

}

#' Volume FileSystem Create Directory
#'
#' @inheritParams auth_params
#' @inheritParams db_volume_read
#' @inheritParams db_sql_warehouse_create
#'
#' @family Volumes FileSystem API
#'
#' @export
db_volume_dir_create <- function(path,
                                 host = db_host(), token = db_token(),
                                 perform_request = TRUE) {

  db_volume_action(
    path = path,
    action = "PUT",
    type = "directories",
    host = host,
    token = token,
    perform_request = perform_request
  )

}

#' Volume FileSystem Delete Directory
#'
#' @inheritParams auth_params
#' @inheritParams db_volume_read
#' @inheritParams db_sql_warehouse_create
#'
#' @family Volumes FileSystem API
#'
#' @export
db_volume_dir_delete <- function(path,
                                 host = db_host(), token = db_token(),
                                 perform_request = TRUE) {

  db_volume_action(
    path = path,
    action = "DELETE",
    type = "directories",
    host = host,
    token = token,
    perform_request = perform_request
  )

}


#' Volume FileSystem Check Directory Exists
#'
#' @inheritParams auth_params
#' @inheritParams db_volume_read
#' @inheritParams db_sql_warehouse_create
#'
#' @family Volumes FileSystem API
#'
#' @export
db_volume_dir_exists <- function(path,
                                 host = db_host(), token = db_token(),
                                 perform_request = TRUE) {

  db_volume_action(
    path = path,
    action = "HEAD",
    type = "directories",
    host = host,
    token = token,
    perform_request = perform_request
  )

}


is_valid_volume_path <- function(path) {
  if (!grepl("^/Volumes/", path)) {
    stop("`path` must start with `/Volumes/`")
  }
  path
}


db_volume_action <- function(path,
                             file = NULL,
                             overwrite = NULL,
                             destination = NULL,
                             action = c("HEAD", "PUT", "DELETE", "GET"),
                             type = c("directories", "files"),
                             host = db_host(), token = db_token(),
                             perform_request = TRUE) {

  path <- is_valid_volume_path(path)
  action <- match.arg(action)
  type <- match.arg(type)

  req <- db_request(
    endpoint = paste0("fs/", type, path),
    method = action,
    version = "2.0",
    host = host,
    token = token
  )

  if (!is.null(overwrite)) {
    req <- req %>%
      httr2::req_url_query(overwrite = ifelse(overwrite, "true", "false"))
  }

  if (type == "files" && action %in% c("GET", "PUT")) {
    if (action == "PUT") {
      req <- httr2::req_body_file(req, file)
    }

    # show progress when uploading and downloading files
    req <- req %>%
      httr2::req_progress(type = ifelse(action == "GET", "down", "up"))
  }


  if (perform_request) {
    resp <- req %>%
      httr2::req_error(is_error = function(resp) httr2::resp_status(resp) == 500) %>%
      httr2::req_perform(path = destination) %>%
      httr2::resp_check_status()

    if (action == "HEAD") {
      return (httr2::resp_status(resp) == 200)
    }

    if (action %in% c("PUT", "DELETE")) {
      return (httr2::resp_status(resp) == 204)
    }

    # GET on files is used for downloading - useful to return location
    if (action == "GET") {
      if (type == "directories") {
        return(httr2::resp_body_json(resp))
      } else {
        return(destination)
      }
    }

  } else {
    req
  }


}
