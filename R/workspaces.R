# https://docs.databricks.com/dev-tools/api/latest/workspace.html

#' Delete Object/Directory (Workspaces)
#'
#' @param path Absolute path of the notebook or directory.
#' @param recursive Flag that specifies whether to delete the object
#' recursively. `False` by default.
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' Delete an object or a directory (and optionally recursively deletes all
#' objects in the directory). If path does not exist, this call returns an error
#' `RESOURCE_DOES_NOT_EXIST`. If path is a non-empty directory and recursive is
#' set to false, this call returns an error `DIRECTORY_NOT_EMPTY.`
#'
#' Object deletion cannot be undone and deleting a directory recursively is not
#' atomic.
#'
#' @family Workspace API
#'
#' @export
db_workspace_delete <- function(path, recursive = FALSE,
                                host = db_host(), token = db_token(),
                                perform_request = TRUE) {
  body <- list(
    path = path,
    recursive = recursive
  )

  req <- db_request(
    endpoint = "workspace/delete",
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

#' Export Notebook or Directory (Workspaces)
#'
#' @param format One of `SOURCE`, `HTML`, `JUPYTER`, `DBC`, `R_MARKDOWN`.
#' Default is `SOURCE`.
#' @inheritParams auth_params
#' @inheritParams db_workspace_delete
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' Export a notebook or contents of an entire directory. If path does not exist,
#' this call returns an error `RESOURCE_DOES_NOT_EXIST.`
#'
#' You can export a directory only in `DBC` format. If the exported data exceeds
#' the size limit, this call returns an error `MAX_NOTEBOOK_SIZE_EXCEEDED.` This
#' API does not support exporting a library.
#'
#' At this time we do not support the `direct_download` parameter and returns a
#' base64 encoded string.
#'
#' [See More](https://docs.databricks.com/dev-tools/api/latest/workspace.html#export).
#'
#' @family Workspace API
#'
#' @return base64 encoded string
#' @export
db_workspace_export <- function(path,
                                format = c("SOURCE", "HTML", "JUPYTER", "DBC", "R_MARKDOWN"),
                                host = db_host(), token = db_token(),
                                perform_request = TRUE) {

  # TODO
  # do not support direct_download being TRUE currently
  # need to make a decision as to if we expect to support saving direct to file
  # gut feel is yes but want to think about it a bit more
  direct_download <- FALSE

  format <- match.arg(format, several.ok = FALSE)

  body <- list(
    path = path,
    format = format,
    direct_download = direct_download
  )

  req <- db_request(
    endpoint = "workspace/export",
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

#' Get Object Status (Workspaces)
#'
#' Gets the status of an object or a directory.
#'
#' @inheritParams auth_params
#' @inheritParams db_workspace_delete
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' If path does not exist, this call returns an error `RESOURCE_DOES_NOT_EXIST.`
#'
#' @family Workspace API
#'
#' @export
db_workspace_get_status <- function(path,
                                    host = db_host(), token = db_token(),
                                    perform_request = TRUE) {
  body <- list(
    path = path
  )

  req <- db_request(
    endpoint = "workspace/get-status",
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

#' Import Notebook/Directory (Workspaces)
#'
#' Import a notebook or the contents of an entire directory.
#'
#' @param file Path of local file to upload. See `formats` parameter.
#' @param content Content to upload, this will be base64-encoded and has a limit
#' of 10MB.
#' @param language One of `R`, `PYTHON`, `SCALA`, `SQL`. Required when `format`
#' is `SOURCE` otherwise ignored.
#' @param overwrite Flag that specifies whether to overwrite existing object.
#' `FALSE` by default. For `DBC` overwrite is not supported since it may contain
#' a directory.
#' @inheritParams auth_params
#' @inheritParams db_workspace_export
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' `file` and `content` are mutually exclusive. If both are specified `content`
#' will be ignored.
#'
#' If path already exists and `overwrite` is set to `FALSE`, this call returns
#' an error `RESOURCE_ALREADY_EXISTS.` You can use only `DBC` format to import
#' a directory.
#'
#' @family Workspace API
#'
#' @export
db_workspace_import <- function(path,
                                file = NULL,
                                content = NULL,
                                format = c("SOURCE", "HTML", "JUPYTER", "DBC", "R_MARKDOWN"),
                                language = NULL,
                                overwrite = FALSE,
                                host = db_host(), token = db_token(),
                                perform_request = TRUE) {
  format <- match.arg(format, several.ok = FALSE)

  if (!is.null(language)) {
    stopifnot(language %in% c("SCALA", "PYTHON", "SQL", "R"))
  }

  body <- list(
    path = path,
    format = format,
    overwrite = ifelse(overwrite, "true", "false"), # doesn't like bool :(
    language = language
  )

  # file takes priority, so don't bother if file is also specified
  if (!is.null(content) && is.null(file)) {
    # contents must be base64 encoded string
    body$content <- base64enc::base64encode(base::charToRaw(content))
  } else if (!is.null(file)) {
    body$content <- curl::form_file(path = file)
  } else {
    stop(cli::format_error(c(
      "Nothing to upload:",
      "x" = "Either `file` or `contents` must be specified."
    )))
  }

  req <- db_request(
    endpoint = "workspace/import",
    method = "POST",
    version = "2.0",
    host = host,
    token = token
  )

  req <- req %>%
    httr2::req_body_multipart(
      path = body$path,
      format = body$format,
      overwrite = body$overwrite,
      language = body$language,
      content = body$content
    )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }

}

#' List Directory Contents (Workspaces)
#'
#' @inheritParams auth_params
#' @inheritParams db_workspace_delete
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' List the contents of a directory, or the object if it is not a directory.
#' If the input path does not exist, this call returns an error
#' `RESOURCE_DOES_NOT_EXIST.`
#'
#' @family Workspace API
#'
#' @export
db_workspace_list <- function(path, host = db_host(), token = db_token(),
                              perform_request = TRUE) {
  body <- list(
    path = path
  )

  req <- db_request(
    endpoint = "workspace/list",
    method = "GET",
    version = "2.0",
    body = body,
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)$objects
  } else {
    req
  }

}

#' Make a Directory (Workspaces)
#'
#' @param path Absolute path of the directory.
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' Create the given directory and necessary parent directories if they do not
#' exists. If there exists an object (not a directory) at any prefix of the
#' input path, this call returns an error `RESOURCE_ALREADY_EXISTS.` If this
#' operation fails it may have succeeded in creating some of the necessary
#' parent directories.
#'
#' @family Workspace API
#'
#' @export
db_workspace_mkdirs <- function(path,
                                host = db_host(), token = db_token(),
                                perform_request = TRUE) {
  body <- list(
    path = path
  )

  req <- db_request(
    endpoint = "workspace/mkdirs",
    method = "POST",
    version = "2.0",
    body = body,
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)
    NULL
  } else {
    req
  }

}
