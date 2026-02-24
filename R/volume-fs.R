#' Volume FileSystem Read
#'
#' Return the contents of a file within a volume (up to 5GiB).
#'
#' @param path Absolute path of the file in the Files API, omitting the initial
#' slash.
#' @param destination Path to write downloaded file to.
#' @param progress If `TRUE`, show progress bar for file operations (default: `TRUE` for uploads/downloads, `FALSE` for other operations)
#' @inheritParams db_dbfs_create
#' @inheritParams db_sql_warehouse_create
#'
#' @family Volumes FileSystem API
#'
#' @export
#' @returns If `perform_request = TRUE`, returns endpoint-specific API output. If `FALSE`, returns an `httr2_request`.
db_volume_read <- function(
  path,
  destination,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE,
  progress = TRUE
) {
  db_volume_action(
    path = path,
    destination = destination,
    action = "GET",
    type = "files",
    host = host,
    token = token,
    perform_request = perform_request,
    progress = progress
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
#' @returns If `perform_request = TRUE`, returns endpoint-specific API output. If `FALSE`, returns an `httr2_request`.
db_volume_delete <- function(
  path,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  db_volume_action(
    path = path,
    action = "DELETE",
    type = "files",
    host = host,
    token = token,
    perform_request = perform_request,
    progress = FALSE
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
#' @returns If `perform_request = TRUE`, returns endpoint-specific API output. If `FALSE`, returns an `httr2_request`.
db_volume_list <- function(
  path,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  # TODO: paginate automatically

  db_volume_action(
    path = path,
    action = "GET",
    type = "directories",
    host = host,
    token = token,
    perform_request = perform_request,
    progress = FALSE
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
#' @returns If `perform_request = TRUE`, returns endpoint-specific API output. If `FALSE`, returns an `httr2_request`.
db_volume_write <- function(
  path,
  file = NULL,
  overwrite = FALSE,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE,
  progress = TRUE
) {
  if (is.null(file)) {
    cli::cli_abort(c(
      "Nothing to upload:",
      "x" = "{.arg file} must be specified."
    ))
  }

  db_volume_action(
    path = path,
    file = file,
    overwrite = overwrite,
    action = "PUT",
    type = "files",
    host = host,
    token = token,
    perform_request = perform_request,
    progress = progress
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
#' @returns If `perform_request = TRUE`, returns endpoint-specific API output. If `FALSE`, returns an `httr2_request`.
db_volume_file_exists <- function(
  path,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  db_volume_action(
    path = path,
    action = "HEAD",
    type = "files",
    host = host,
    token = token,
    perform_request = perform_request,
    progress = FALSE
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
#' @returns If `perform_request = TRUE`, returns endpoint-specific API output. If `FALSE`, returns an `httr2_request`.
db_volume_dir_create <- function(
  path,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  db_volume_action(
    path = path,
    action = "PUT",
    type = "directories",
    host = host,
    token = token,
    perform_request = perform_request,
    progress = FALSE
  )
}

#' Volume FileSystem Delete Directory
#'
#' @param recursive If `TRUE`, recursively delete directory contents (default: `FALSE`)
#' @param verbose If `TRUE`, announce each file/directory deletion (default: `FALSE`)
#' @inheritParams auth_params
#' @inheritParams db_volume_read
#' @inheritParams db_sql_warehouse_create
#'
#' @family Volumes FileSystem API
#'
#' @export
#' @returns If `perform_request = TRUE`, returns endpoint-specific API output. If `FALSE`, returns an `httr2_request`.
db_volume_dir_delete <- function(
  path,
  recursive = FALSE,
  verbose = FALSE,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  if (recursive) {
    # Recursively delete contents first
    db_volume_recursive_delete_contents(
      path,
      host = host,
      token = token,
      verbose = verbose
    )
  }

  # Delete the directory itself
  # For recursive mode, always perform requests; for non-recursive, respect parameter
  effective_perform_request <- if (recursive) TRUE else perform_request

  if (verbose && effective_perform_request) {
    cli::cli_inform("Deleting directory: {.path {path}}")
  }

  db_volume_action(
    path = path,
    action = "DELETE",
    type = "directories",
    host = host,
    token = token,
    perform_request = effective_perform_request,
    progress = FALSE
  )
}

#' Recursively delete all contents of a volume directory
#' @keywords internal
db_volume_recursive_delete_contents <- function(
  path,
  host,
  token,
  verbose = FALSE
) {
  tryCatch(
    {
      # List directory contents
      contents <- db_volume_list(path, host = host, token = token)$contents

      if (!is.null(contents) && length(contents) > 0) {
        # Delete all files and subdirectories
        for (item in contents) {
          item_path <- fs::path(path, item$name)

          if (isTRUE(item$is_directory)) {
            # Recursively delete subdirectory and all its contents
            db_volume_dir_delete(
              item_path,
              recursive = TRUE,
              verbose = verbose,
              host = host,
              token = token
            )
          } else {
            # Delete file
            if (verbose) {
              cli::cli_inform("Deleting file: {.path {item_path}}")
            }
            db_volume_delete(item_path, host = host, token = token)
          }
        }
      }
    },
    error = function(e) {
      # If listing fails, directory might be empty or not exist, continue
      # This handles edge cases like permissions or already deleted directories
    }
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
#' @returns If `perform_request = TRUE`, returns endpoint-specific API output. If `FALSE`, returns an `httr2_request`.
db_volume_dir_exists <- function(
  path,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  db_volume_action(
    path = path,
    action = "HEAD",
    type = "directories",
    host = host,
    token = token,
    perform_request = perform_request,
    progress = FALSE
  )
}


is_valid_volume_path <- function(path) {
  if (!startsWith(path, "/Volumes/")) {
    cli::cli_abort("{.arg path} must start with {.path /Volumes/}")
  }
  path
}


db_volume_action <- function(
  path,
  file = NULL,
  overwrite = NULL,
  destination = NULL,
  action = c("HEAD", "PUT", "DELETE", "GET"),
  type = c("directories", "files"),
  host = db_host(),
  token = db_token(),
  perform_request = TRUE,
  progress = TRUE
) {
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
    req <- req |>
      httr2::req_url_query(overwrite = ifelse(overwrite, "true", "false"))
  }

  if (type == "files" && action %in% c("GET", "PUT")) {
    if (action == "PUT") {
      req <- httr2::req_body_file(req, file)
    }

    # show progress when uploading and downloading files
    if (progress) {
      # Use httr2 progress with custom formatting
      req <- req |>
        httr2::req_progress(
          type = ifelse(action == "GET", "down", "up")
        )
    }
  } else if (type == "files" && action == "PUT") {
    # Add body file even without progress
    req <- httr2::req_body_file(req, file)
  }

  if (perform_request) {
    resp <- req |>
      httr2::req_error(is_error = function(resp) {
        httr2::resp_status(resp) == 500
      }) |>
      httr2::req_perform(path = destination) |>
      httr2::resp_check_status()

    if (action == "HEAD") {
      return(httr2::resp_status(resp) == 200)
    }

    if (action %in% c("PUT", "DELETE")) {
      return(httr2::resp_status(resp) == 204)
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

#' Upload Directory to Volume in Parallel
#'
#' Upload all files from a local directory to a volume directory using parallel requests.
#'
#' @param local_dir Path to local directory containing files to upload
#' @param volume_dir Volume directory path (must start with /Volumes/)
#' @param overwrite Flag to overwrite existing files (default: `TRUE`)
#' @param recursive If `TRUE`, recursively include subdirectories (default: `TRUE`).
#' If `FALSE`, only top-level files are transferred.
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @returns TRUE if all uploads successful
#' @family Volumes FileSystem API
#'
#' @export
db_volume_upload_dir <- function(
  local_dir,
  volume_dir,
  overwrite = TRUE,
  recursive = TRUE,
  host = db_host(),
  token = db_token()
) {
  # Validate inputs
  if (!fs::dir_exists(local_dir)) {
    cli::cli_abort("Local directory does not exist: {local_dir}")
  }

  volume_dir <- is_valid_volume_path(volume_dir)

  # Create volume directory
  db_volume_dir_create(volume_dir, host = host, token = token)

  # map files and generate requests
  requests <- fs::dir_map(
    local_dir,
    recurse = recursive,
    type = "file",
    fun = function(local_file) {
      if (recursive) {
        # Preserve relative path structure
        rel_path <- fs::path_rel(local_file, start = local_dir)
        volume_file <- fs::path(volume_dir, rel_path)

        # Create subdirectories if needed
        volume_subdir <- fs::path_dir(volume_file)
        if (volume_subdir != volume_dir) {
          db_volume_dir_create(volume_subdir, host = host, token = token)
        }
      } else {
        # Upload to root of volume directory
        volume_file <- fs::path(volume_dir, fs::path_file(local_file))
      }

      # Create upload request (no individual progress for parallel uploads)
      db_volume_action(
        path = volume_file,
        file = local_file,
        overwrite = overwrite,
        action = "PUT",
        type = "files",
        host = host,
        token = token,
        perform_request = FALSE,
        progress = FALSE
      )
    }
  )

  if (length(requests) == 0) {
    cli::cli_warn("No files found in directory: {local_dir}")
    return(TRUE)
  }

  # Execute parallel uploads with styled progress bars
  httr2::req_perform_parallel(
    requests,
    on_error = "stop",
    progress = list(
      clear = FALSE,
      type = "iterator",
      format = "Uploading {cli::pb_bar} {cli::pb_percent} [{cli::pb_elapsed}]",
      format_done = "{cli::col_green('\\u2714')} Data uploaded [{cli::pb_elapsed}]",
      format_failed = "Data upload failed [{cli::pb_elapsed}]"
    )
  )

  TRUE
}

#' Download Directory from Volume in Parallel
#'
#' Download files from a volume directory to a local directory using parallel requests.
#'
#' @param volume_dir Volume directory path (must start with /Volumes/)
#' @param local_dir Path to local directory where files will be downloaded
#' @param overwrite Flag to overwrite existing local files (default: `TRUE`)
#' @param recursive If `TRUE`, recursively include subdirectories (default: `TRUE`).
#' If `FALSE`, only top-level files are transferred.
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @returns TRUE if all downloads successful
#' @family Volumes FileSystem API
#'
#' @export
db_volume_download_dir <- function(
  volume_dir,
  local_dir,
  overwrite = TRUE,
  recursive = TRUE,
  host = db_host(),
  token = db_token()
) {
  volume_dir <- is_valid_volume_path(volume_dir)

  if (fs::file_exists(local_dir) && !fs::dir_exists(local_dir)) {
    cli::cli_abort("{.arg local_dir} exists and is not a directory: {.path {local_dir}}")
  }

  fs::dir_create(local_dir, recurse = TRUE)

  volume_files <- db_volume_list_files_recursive(
    path = volume_dir,
    recurse = recursive,
    host = host,
    token = token
  )

  if (length(volume_files) == 0) {
    cli::cli_warn("No files found in volume directory: {volume_dir}")
    return(TRUE)
  }

  local_files <- purrr::map_chr(volume_files, function(volume_file) {
    if (recursive) {
      relative_path <- fs::path_rel(volume_file, start = volume_dir)
      fs::path(local_dir, relative_path)
    } else {
      fs::path(local_dir, fs::path_file(volume_file))
    }
  })

  # Ensure target directories exist before download.
  local_dirs <- unique(fs::path_dir(local_files))
  purrr::walk(local_dirs, fs::dir_create, recurse = TRUE)

  if (!overwrite) {
    existing_files <- local_files[fs::file_exists(local_files)]
    if (length(existing_files) > 0) {
      cli::cli_abort(c(
        "Local files already exist:",
        "x" = "{length(existing_files)} file(s) already exist. Set {.arg overwrite = TRUE} to replace them.",
        "i" = "Example existing file: {.path {existing_files[[1]]}}"
      ))
    }
  }

  requests <- purrr::map(
    volume_files,
    db_volume_action,
    action = "GET",
    type = "files",
    host = host,
    token = token,
    perform_request = FALSE,
    progress = FALSE
  )

  httr2::req_perform_parallel(
    requests,
    paths = local_files,
    on_error = "stop",
    progress = list(
      clear = FALSE,
      type = "iterator",
      format = "Downloading {cli::pb_bar} {cli::pb_percent} [{cli::pb_elapsed}]",
      format_done = "{cli::col_green('\\u2714')} Data downloaded [{cli::pb_elapsed}]",
      format_failed = "Data download failed [{cli::pb_elapsed}]"
    )
  )

  TRUE
}

#' Recursively collect file paths from a volume directory
#' @keywords internal
db_volume_list_files_recursive <- function(
  path,
  recurse = TRUE,
  host,
  token
) {
  contents <- db_volume_list(path = path, host = host, token = token)$contents

  if (is.null(contents) || length(contents) == 0) {
    return(character(0))
  }

  files <- character(0)

  for (item in contents) {
    item_path <- fs::path(path, item$name)

    if (isTRUE(item$is_directory)) {
      if (recurse) {
        files <- c(
          files,
          db_volume_list_files_recursive(
            path = item_path,
            recurse = recurse,
            host = host,
            token = token
          )
        )
      }
    } else {
      files <- c(files, item_path)
    }
  }

  files
}
