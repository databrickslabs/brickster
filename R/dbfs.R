# Databricks DBFS API

#' DBFS Create
#'
#' Open a stream to write to a file and returns a handle to this stream.
#'
#' @param path The path of the new file. The path should be the absolute DBFS
#' path (for example `/mnt/my-file.txt`).
#' @param overwrite Boolean, specifies whether to overwrite existing file or
#' files.
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' There is a 10 minute idle timeout on this handle. If a file or directory
#' already exists on the given path and overwrite is set to `FALSE`, this call
#' throws an exception with `RESOURCE_ALREADY_EXISTS.`
#'
#' @section Typical File Upload Flow:
#' * Call create and get a handle via [db_dbfs_create()]
#' * Make one or more [db_dbfs_add_block()] calls with the handle you have
#' * Call [db_dbfs_close()] with the handle you have
#'
#' @family DBFS API
#'
#' @return Handle which should subsequently be passed into [db_dbfs_add_block()]
#' and [db_dbfs_close()] when writing to a file through a stream.
#' @export
db_dbfs_create <- function(
  path,
  overwrite = FALSE,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  body <- list(
    path = path,
    overwrite = overwrite
  )

  req <- db_request(
    endpoint = "dbfs/create",
    method = "POST",
    version = "2.0",
    body = body,
    host = host,
    token = token
  )

  if (perform_request) {
    res <- db_perform_request(req)
    # int64 is unreliable - use string
    as.character(res$handle)
  } else {
    req
  }
}


#' DBFS Add Block
#'
#' Append a block of data to the stream specified by the input handle.
#'
#' @param handle Handle on an open stream.
#' @param data Either a path for file on local system or a character/raw
#' vector that will be base64-encoded. This has a limit of 1 MB.
#' @param convert_to_raw Boolean (Default: `FALSE`), if `TRUE` will convert
#' character vector to raw via [as.raw()].
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#'  * If the handle does not exist, this call will throw an exception with
#'  `RESOURCE_DOES_NOT_EXIST.`
#'  * If the block of data exceeds 1 MB, this call will throw an exception with
#'  `MAX_BLOCK_SIZE_EXCEEDED.`
#'
#' @inheritSection db_dbfs_create Typical File Upload Flow
#'
#' @family DBFS API
#'
#' @export
#' @importFrom stats setNames
#' @importFrom utils object.size
db_dbfs_add_block <- function(
  handle,
  data,
  convert_to_raw = FALSE,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  # `base64enc::base64encode()` can't accept strings
  # if `convert_to_raw` is TRUE then convert so that the string is encoded
  # otherwise it will assume it's a file path on the local system
  if (convert_to_raw) {
    if (is.character(data)) {
      data <- charToRaw(data)
    } else {
      data <- as.raw(data)
    }
  }

  # encode data as base64
  encoded_data <- base64enc::base64encode(data)

  # limit of 1MB per block
  obj_size <- round(as.integer(object.size(encoded_data)) / 1024^2, 4)

  if (obj_size > 1L) {
    cli::cli_abort(c(
      "Max Block Size Exceeded:",
      "x" = "Maximum block size is 1MB, block was {obj_size}MB."
    ))
  }

  body <- list(
    data = encoded_data,
    handle = handle
  )

  req <- db_request(
    endpoint = "dbfs/add-block",
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


#' DBFS Close
#'
#' Close the stream specified by the input handle.
#'
#' @param handle The handle on an open stream. This field is required.
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' If the handle does not exist, this call throws an exception with
#' `RESOURCE_DOES_NOT_EXIST.`
#'
#' @inheritSection db_dbfs_create Typical File Upload Flow
#'
#' @family DBFS API
#'
#' @return HTTP Response
#' @export
db_dbfs_close <- function(
  handle,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  body <- list(handle = handle)

  req <- db_request(
    endpoint = "dbfs/close",
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


#' DBFS Get Status
#'
#' Get the file information of a file or directory.
#'
#' @inheritParams auth_params
#' @inheritParams db_dbfs_create
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' * If the file or directory does not exist, this call throws an exception with
#' `RESOURCE_DOES_NOT_EXIST.`
#'
#' @family DBFS API
#'
#' @export
db_dbfs_get_status <- function(
  path,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  body <- list(path = path)

  req <- db_request(
    endpoint = "dbfs/get-status",
    method = "GET",
    version = "2.0",
    body = body,
    host = db_host(),
    token = db_token()
  )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }
}

#' DBFS List
#'
#' List the contents of a directory, or details of the file.
#'
#' @inheritParams auth_params
#' @inheritParams db_dbfs_create
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' When calling list on a large directory, the list operation will time out
#' after approximately 60 seconds.
#'
#' We **strongly** recommend using list only on
#' directories containing less than 10K files and discourage using the DBFS REST
#' API for operations that list more than 10K files. Instead, we recommend that
#' you perform such operations in the context of a cluster, using the File
#' system utility (`dbutils.fs`), which provides the same functionality without
#' timing out.
#'
#' * If the file or directory does not exist, this call throws an exception with
#' `RESOURCE_DOES_NOT_EXIST.`
#'
#' @family DBFS API
#'
#' @return data.frame
#' @export
db_dbfs_list <- function(
  path,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  body <- list(path = path)

  req <- db_request(
    endpoint = "dbfs/list",
    method = "GET",
    version = "2.0",
    body = body,
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req, simplifyDataFrame = T)$files
  } else {
    req
  }
}

#' DBFS mkdirs
#'
#' Create the given directory and necessary parent directories if they do not
#' exist.
#'
#' @inheritParams db_dbfs_create
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' * If there exists a file (not a directory) at any prefix of the input path,
#' this call throws an exception with `RESOURCE_ALREADY_EXISTS.`
#' * If this operation fails it may have succeeded in creating some of the
#' necessary parent directories.
#'
#' @family DBFS API
#'
#' @export
db_dbfs_mkdirs <- function(
  path,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  body <- list(
    path = path
  )

  req <- db_request(
    endpoint = "dbfs/mkdirs",
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

#' DBFS Move
#'
#' Move a file from one location to another location within DBFS.
#'
#' @param source_path The source path of the file or directory. The path
#' should be the absolute DBFS path (for example, `/mnt/my-source-folder/`).
#' @param destination_path The destination path of the file or directory. The
#' path should be the absolute DBFS path (for example,
#' `/mnt/my-destination-folder/`).
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' If the given source path is a directory, this call always recursively moves
#' all files.
#'
#' When moving a large number of files, the API call will time out after
#' approximately 60 seconds, potentially resulting in partially moved data.
#' Therefore, for operations that move more than 10K files, we **strongly**
#' discourage using the DBFS REST API. Instead, we recommend that you perform
#' such operations in the context of a cluster, using the File system utility
#' (`dbutils.fs`) from a notebook, which provides the same functionality without
#' timing out.
#'
#' * If the source file does not exist, this call throws an exception with
#' `RESOURCE_DOES_NOT_EXIST.`
#' * If there already exists a file in the destination path, this call throws an
#' exception with `RESOURCE_ALREADY_EXISTS.`
#'
#' @family DBFS API
#'
#' @export
db_dbfs_move <- function(
  source_path,
  destination_path,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  body <- list(
    source_path = source_path,
    destination_path = destination_path
  )

  req <- db_request(
    endpoint = "dbfs/move",
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

#' DBFS Delete
#'
#' @param recursive Whether or not to recursively delete the directory’s
#' contents. Deleting empty directories can be done without providing the recursive flag.
#' @inheritParams auth_params
#' @inheritParams db_dbfs_create
#' @inheritParams db_sql_warehouse_create
#'
#' @family DBFS API
#'
#' @export
db_dbfs_delete <- function(
  path,
  recursive = FALSE,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  body <- list(
    path = path,
    recursive = recursive
  )

  req <- db_request(
    endpoint = "dbfs/delete",
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

#' DBFS Put
#'
#' Upload a file through the use of multipart form post.
#'
#' @param file Path to a file on local system, takes precedent over `path`.
#' @param contents String that is base64 encoded.
#' @param overwrite Flag (Default: `FALSE`) that specifies whether to overwrite
#' existing files.
#' @inheritParams auth_params
#' @inheritParams db_dbfs_create
#'
#' @details
#' Either `contents` or `file` must be specified. `file` takes precedent over
#' `contents` if both are specified.
#'
#' Mainly used for streaming uploads, but can also be used as a convenient
#' single call for data upload.
#'
#' The amount of data that can be passed using the contents parameter is limited
#' to 1 MB if specified as a string (`MAX_BLOCK_SIZE_EXCEEDED` is thrown if
#' exceeded) and 2 GB as a file.
#'
#' @family DBFS API
#'
#' @export
db_dbfs_put <- function(
  path,
  file = NULL,
  contents = NULL,
  overwrite = FALSE,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  body <- list(
    path = path,
    overwrite = from_logical(overwrite)
  )

  # file takes priority, so don't bother if file is also specified
  if (!is.null(contents) && is.null(file)) {
    # contents must be base64 encoded string
    body$contents <- base64enc::base64encode(charToRaw(contents))
  } else if (!is.null(file)) {
    body$contents <- curl::form_file(path = file)
  } else {
    cli::cli_abort(c(
      "Nothing to upload:",
      "x" = "Either {.arg file} or {.arg contents} must be specified."
    ))
  }

  req <- db_request(
    endpoint = "dbfs/put",
    method = "POST",
    version = "2.0",
    host = host,
    token = token
  )

  if (perform_request) {
    req |>
      httr2::req_body_multipart(!!!body) |>
      httr2::req_error(body = db_req_error_body) |>
      httr2::req_perform() |>
      httr2::resp_body_json()
  } else {
    req
  }
}


#' DBFS Read
#'
#' Return the contents of a file.
#'
#' @param offset Offset to read from in bytes.
#' @param length Number of bytes to read starting from the offset. This has a
#' limit of 1 MB, and a default value of 0.5 MB.
#' @inheritParams auth_params
#' @inheritParams db_dbfs_create
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' If offset + length exceeds the number of bytes in a file, reads contents
#' until the end of file.
#'
#' * If the file does not exist, this call throws an exception with
#' `RESOURCE_DOES_NOT_EXIST.`
#' * If the path is a directory, the read length is negative, or if the offset
#' is negative, this call throws an exception with `INVALID_PARAMETER_VALUE.`
#' * If the read length exceeds 1 MB, this call throws an exception with
#' `MAX_READ_SIZE_EXCEEDED.`
#'
#' @family DBFS API
#'
#' @export
db_dbfs_read <- function(
  path,
  offset = 0,
  length = NULL,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  body <- list(
    path = path,
    offset = offset,
    length = length
  )

  req <- db_request(
    endpoint = "dbfs/read",
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
