brickster_actions <- function(host) {
  list(
    Workspace = list(
      icon = "",
      callback = function() {
        utils::browseURL(host)
      }
    ),
    SQL = list(
      icon = "",
      callback = function() {
        utils::browseURL(paste0(host, "sql"))
      }
    ),
    `Upload to DBFS` = list(
      icon = "",
      callback = function() {
        path <- rstudioapi::selectFile(
          caption = "Select file to upload to DBFS",
          existing = TRUE
        )
        if (!is.null(path)) {
          dbfs_path <- rstudioapi::showPrompt(
            title = "File Destination (DBFS Path)",
            message = "File Destination (DBFS Path):",
            default = "/"
          )
        }
        if (dbfs_path != "") {
          brickster::db_dbfs_put(
            path = dbfs_path,
            file = path,
            overwrite = TRUE
          )
        }
      }
    ),
    `Workspace Import` = list(
      icon = "",
      callback = function() {
        path <- rstudioapi::selectFile(
          caption = "Select file to upload to DBFS",
          existing = TRUE,
          filter = "Databricks Permitted Files (*.R | *.r | *.py | *.scala | *.sql | *.dbc | *.html | *.ipynb)"
        )
        if (!is.null(path)) {
          ws_path <- rstudioapi::showPrompt(
            title = "Import Path (Workspace Path)",
            message = "Workspace Destination:",
            default = "/Shared/"
          )
        }
        if (ws_path != "") {

          filename <- base::basename(path)
          ext <- gsub(".*\\.(.*)", "\\1", filename)

          if (ext %in% c("R", "r", "py", "scala", "sql")) {
            lang <- toupper(ext)
            format <- "SOURCE"
          } else {
            lang <- NULL
            format <- toupper(ifelse(ext == "ipynb", "jupyter", ext))
          }
          brickster::db_workspace_import(
            file = path,
            path = ws_path,
            format = format,
            language = lang,
            overwrite = TRUE
          )
        }
      }
    )
  )
}

get_id_from_panel_name <- function(x, host, token) {
  id <- sub(pattern = ".*\\((.*)\\)", replacement = "\\1", x = x)
}

get_dbfs_items <- function(path = "/", host, token, is_file = FALSE) {
  items <- brickster::db_dbfs_list(path = path, host = host, token = token)
  if (is_file) {
    data.frame(
      name = c("file size", "modification time"),
      type = c(
        base::format(base::structure(items$file_size, class = "object_size"), units = "auto"),
        as.character(as.POSIXct(items$modification_time/1000, origin = "1970-01-01", tz = "UTC"))
      )
    )
  } else {
    data.frame(
      name = gsub(pattern = "^.*\\/(.*)$", replacement = "\\1", x = items$path),
      type = ifelse(items$is_dir, "folder", "files")
    )
  }
}

#' @importFrom rlang .data
get_notebook_items <- function(path = "/", host, token, is_nb = FALSE) {

  items <- brickster::db_workspace_list(path = path, host = host, token = token)

  if (is_nb) {
    info <- data.frame(
      name = c("language", "object id"),
      type = c(tolower(items[[1]]$language), as.character(items[[1]]$object_id))
    )
  } else {
    info <- purrr::map_dfr(items, function(x) {
      list(
        name = gsub(pattern = "^.*\\/(.*)$", replacement = "\\1", x = x$path),
        type = x$object_type
      )
    })
    if (nrow(info) > 0) {
      info <- dplyr::filter(info, .data$type %in% c("DIRECTORY", "NOTEBOOK"))
      info <- dplyr::mutate(info, type = dplyr::if_else(.data$type == "NOTEBOOK", "notebook", "folder"))
    } else {
      data.frame(name = NULL, type = NULL)
    }
  }

  info

}

get_clusters <- function(host, token) {
  clusters <- brickster::db_cluster_list(host = host, token = token)
  purrr::map_dfr(clusters, function(x) {
    status <- dplyr::case_when(
      x$state == "PENDING"     ~ "\U0001f7e1",
      x$state == "RUNNING"     ~ "\U0001f7e2",
      x$state == "RESTARTING"  ~ "\U0001f504",
      x$state == "RESIZING"    ~ "\U0001f504",
      x$state == "TERMINATING" ~ "\U0001f534",
      x$state == "TERMINATED"  ~ "\u26aa\ufe0f",
      x$state == "ERROR"       ~ "\u26a0️",
      x$state == "UNKNOWN"     ~ "\u2753"
    )
    list(
      name = as.character(glue::glue("{status}{x$cluster_name} ({x$cluster_id})")),
      type = "cluster"
    )
  })
}

get_cluster <- function(id, host, token) {
  x <- brickster::db_cluster_get(id, host, token)
  info <- list(
    "name" = x$cluster_name,
    "id" = id,
    "creator" = x$creator_user_name,
    "runtime" = x$spark_version,
    "worker node type" = x$node_type_id,
    "driver node type" = x$driver_node_type_id,
    "autotermination minutes" = x$autotermination_minutes,
    "start time" = as.character(as.POSIXct(x$start_time/1000, origin = "1970-01-01", tz = "UTC")),
    "# workers" = ifelse(is.null(x$num_workers), 0L, x$num_workers),
    "cores" = ifelse(is.null(x$cluster_cores), 0L, x$cluster_cores),
    "memory (mb)" = ifelse(is.null(x$cluster_memory_mb), 0L, x$cluster_memory_mb)
  )
  data.frame(
    name = names(info),
    type = unname(unlist(info))
  )
}

get_warehouses <- function(host, token) {
  warehouses <- brickster::db_sql_warehouse_list(host = host, token = token)
  purrr::map_dfr(warehouses, function(x) {
    status <- dplyr::case_when(
      x$state == "STARTING" ~ "",
      x$state == "RUNNING"  ~ "\U0001f7e2",
      x$state == "STOPPING" ~ "\U0001f534",
      x$state == "STOPPED"  ~ "\u26aa\ufe0f",
      x$state == "DELETING" ~ "\U0001f534",
      x$state == "DELETED"  ~ "\U0001f534"
    )
    list(
      name = as.character(glue::glue("{status}{x$name} ({x$id})")),
      type = "warehouse"
    )
  })
}

get_warehouse <- function(id, host, token) {
  x <- brickster::db_sql_warehouse_get(id, host, token)
  info <- list(
    "name" = x$name,
    "id" = id,
    "creator" = x$creator_name,
    "channel" = x$channel$name,
    "serverless" = x$enable_serverless_compute,
    "size" = x$cluster_size,
    "# clusters" = x$num_clusters,
    "clusters (min)" = x$min_num_clusters,
    "clusters (max)" = x$max_num_clusters,
    "autostop minutes" = x$auto_stop_mins
  )
  data.frame(
    name = names(info),
    type = unname(unlist(info))
  )
}

list_objects <- function(host, token,
                         type = NULL,
                         dbfs = NULL,
                         notebooks = NULL,
                         workspace = NULL,
                         folder = NULL,
                         clusters = NULL,
                         warehouses = NULL,
                         ...) {

  # clusters
  if (!is.null(clusters)) {
    objects <- get_clusters(host = host, token = token)
    return(objects)
  }

  # warehouses
  if (!is.null(warehouses)) {
    objects <- get_warehouses(host = host, token = token)
    return(objects)
  }

  # dbfs
  if (!is.null(dbfs)) {
    if (is.null(folder)) {
      objects <- get_dbfs_items(path = "/", host = host, token = token)
    } else {
      objects <- get_dbfs_items(path = folder, host = host, token = token)
    }
    return(objects)
  }

  # workspace notebooks
  if (!is.null(notebooks)) {
    if (is.null(folder)) {
      objects <- get_notebook_items(path = "/", host = host, token = token)
    } else {
      objects <- get_notebook_items(path = folder, host = host, token = token)
    }
    return(objects)
  }

  # baseline view (static)
  data.frame(
    name = c("Clusters", "SQL Warehouses", "File System (DBFS)", "Workspace (Notebooks)"),
    type = c("clusters", "warehouses", "dbfs", "notebooks")
  )

}

list_columns <- function(host, token, path = "", ...) {

  dots <- list(...)
  leaf <- dots[length(dots)]
  leaf_type <- names(leaf)

  # for clusters and warehouses things are simple
  if (leaf_type == "cluster") {
    info <- get_cluster(id = get_id_from_panel_name(leaf), host = host, token = token)
    return(info)
  }

  if (leaf_type == "warehouse") {
    info <- get_warehouse(id = get_id_from_panel_name(leaf), host = host, token = token)
    return(info)
  }

  # folders can be nested indefinitely, resolve folders into a path
  if ("folder" %in% names(dots)) {
    path <- paste0("/", dots[names(dots) == "folder"], collapse = "")
  }

  if (leaf_type == "folder") {
    info <- get_dbfs_items(path = path, host = host, token = token)
  }

  if (leaf_type == "files") {
    info <- get_dbfs_items(
      path = paste0(path, "/", leaf),
      host = host,
      token = token,
      is_file = TRUE
    )
  }

  if (leaf_type == "notebook") {
    info <- get_notebook_items(
      paste0(path, "/", leaf),
      host = host,
      token = token,
      is_nb = TRUE
    )
  }

  info

}

preview_object <- function(host, token, rowLimit,
                           path = "",
                           cluster = NULL,
                           warehouse = NULL,
                           files = NULL,
                           notebook = NULL,
                           ...) {

  if (!is.null(cluster)) {
    id <- get_id_from_panel_name(cluster)
    url <- glue::glue("{host}?o={db_wsid()}#setting/clusters/{id}/configuration")
    return(utils::browseURL(url))
  }

  if (!is.null(warehouse)) {
    id <- get_id_from_panel_name(warehouse)
    url <- glue::glue("{host}sql/warehouses/{id}")
    return(utils::browseURL(url))
  }

  # folders can be nested indefinitely
  dots <- list(...)
  if ("folder" %in% names(dots)) {
    path <- paste0("/", dots[names(dots) == "folder"], collapse = "")
  }

  if (!is.null(notebook)) {
    # export notebook as ipynb
    content <- brickster::db_workspace_export(
      path = paste0(path, "/", notebook),
      format = "JUPYTER"
    )

    # save to temporary directory and open
    dir <- tempdir()
    content_text <- rawToChar(base64enc::base64decode(content$content))
    nb_path <- file.path(dir, paste(notebook, content$file_type, sep = "."))
    rmd_path <- file.path(dir, paste(notebook, "rmd", sep = "."))
    base::writeLines(content_text, con = nb_path)
    rmarkdown::convert_ipynb(input = nb_path, output = rmd_path)
    rstudioapi::navigateToFile(file = rmd_path)

  }

  if (!is.null(files)) {

    # TODO: check file size first, don't download if >10mb
    # download from dbfs
    content <- brickster::db_dbfs_read(path = paste0(path, "/", files))

    # save to temporary directory and open
    dir <- tempdir()
    content_text <- rawToChar(base64enc::base64decode(content$data))
    file_path <- file.path(dir, files)
    base::writeLines(content_text, con = file_path)
    rstudioapi::navigateToFile(file = file_path)
  }

}

#' Connect to Databricks Workspace
#'
#' @inheritParams auth_params
#' @param name Desired name to assign the connection
#'
#' @export
#'
#' @examples
#' \dontrun{
#' open_workspace(host = db_host(), token = db_token, name = "MyWorkspace")
#' }
#' @importFrom glue glue
open_workspace <- function(host = db_host(), token = db_token(), name = NULL) {
  observer <- getOption("connectionObserver")
  if (!is.null(observer)) {

    connection_string <- glue::glue(
      "library(brickster)\nopen_workspace(host = db_host(), token = db_token())
    ")

    display_name <- if (!is.null(name)) name else host

    observer$connectionOpened(
      type = "workspace",
      host = host,
      displayName = display_name,
      icon = system.file("icons", "logo.png", package = "brickster"),
      connectCode = connection_string,
      disconnect = function() {
        close_workspace(host)
      },
      listObjectTypes = function() {
        list_objects_types()
      },
      listObjects = function(type = "root", ...) {

        dots <- list(...)

        # folders can be nested indefinitely
        if ("folder" %in% names(dots)) {
          path <- paste0("/", dots[names(dots) == "folder"], collapse = "")
        } else {
          path <- "/"
        }

        objects <- list_objects(
          host,
          token,
          folder = path,
          files = dots$files,
          warehouses = dots$warehouses,
          clusters = dots$clusters,
          dbfs = dots$dbfs,
          notebooks = dots$notebooks
        )
        return(objects)
      },
      listColumns = function(...) {
        columns <- list_columns(host = host, token = token, ...)
        return(columns)
      },
      previewObject = function(rowLimit, ...) {
        preview_object(host = host, token = token, rowLimit = rowLimit, ...)
      },
      actions = brickster_actions(host),
      connectionObject = host
    )
  }
}

#' Close Databricks Workspace Connection
#'
#' @inheritParams auth_params
#'
#' @export
#'
#' @examples
#' \dontrun{
#' close_workspace(host = db_host())
#' }
close_workspace <- function(host = db_host()) {
  observer <- getOption("connectionObserver")
  if (!is.null(observer)) {
    observer$connectionClosed(type = "workspace", host = host)
  }
}

list_objects_types <- function() {
  list(
    workspace = list(contains = list(
      clusters = list(contains = list(
        cluster = list(
          icon = system.file("icons", "magnify.png", package = "brickster"),
          contains = "data"
        )
      )),
      warehouses = list(contains = list(
        warehouse = list(
          icon = system.file("icons", "magnify.png", package = "brickster"),
          contains = "data"
        )
      )),
      dbfs = list(contains = list(
        folder = list(contains = list(
          files = list(
            icon = system.file("icons", "file.png", package = "brickster"),
            contains = "data"
          )
        ))
      )),
      notebooks = list(contains = list(
        folder = list(contains = list(
          notebook = list(
            icon = system.file("icons", "notebook.png", package = "brickster"),
            contains = "data"
          )
        ))
      ))
    ))
  )
}
