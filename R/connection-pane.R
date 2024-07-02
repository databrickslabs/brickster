# BACKLOG:
# - can only return so many objects at once, how to paginate via UI?
#   - impacts experiments, model registry, etc.

# nocov start
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
          db_dbfs_put(
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
          db_workspace_import(
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
# nocov end

get_id_from_panel_name <- function(x) {
  sub(pattern = ".*\\((.*)\\).*", replacement = "\\1", x = x)
}

readable_time <- function(x) {
  time <- as.POSIXct(
    x = x/1000,
    origin = "1970-01-01",
    tz = "UTC"
  )
  as.character(time)
}


get_dbfs_items <- function(path = "/", host, token, is_file = FALSE) {
  items <- db_dbfs_list(path = path, host = host, token = token)
  if (is_file) {
    data.frame(
      name = c("file size", "modification time"),
      type = c(
        base::format(base::structure(items$file_size, class = "object_size"), units = "auto"),
        readable_time(items$modification_time)
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

  items <- db_workspace_list(path = path, host = host, token = token)

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

get_catalogs <- function(host, token) {
  catalogs <- db_uc_catalogs_list(host = host, token = token)
  data.frame(
    name = purrr::map_chr(catalogs, "name"),
    type = "catalog"
  )
  if (length(catalogs) > 0) {
    data.frame(
      name = purrr::map_chr(catalogs, "name"),
      type = "catalog"
    )
  } else {
    data.frame(name = NULL, type = NULL)
  }
}

get_schemas <- function(catalog, host, token) {
  schemas <- db_uc_schemas_list(
    catalog = catalog,
    host = host,
    token = token
  )
  if (length(schemas) > 0) {
    data.frame(
      name = purrr::map_chr(schemas, "name"),
      type = "schema"
    )
  } else {
    data.frame(name = NULL, type = NULL)
  }
}

get_tables <- function(catalog, schema, host, token) {
  tables <- db_uc_tables_list(
    catalog = catalog,
    schema = schema,
    host = host,
    token = token
  )
  if (length(tables) > 0) {
    data.frame(
      name = purrr::map_chr(tables, "name"),
      type = "table"
    )
  } else {
    data.frame(name = NULL, type = NULL)
  }
}

get_table_data <- function(catalog, schema, table, host, token, metadata = TRUE) {
  # if metadata is TRUE then return metadata, otherwise columns
  tbl <- db_uc_tables_get(
    catalog = catalog,
    schema = schema,
    table = table,
    host = host,
    token = token,
  )
  # TODO: handle edge case errors?
  if (metadata) {
    if (tbl$table_type == "VIEW") {
      info <- list(
        "table type" = tbl$table_type,
        "view definition" = tbl$view_definition,
        "full name" = tbl$full_name,
        "owner" = tbl$owner,
        "created at" = readable_time(tbl$created_at),
        "created by" = tbl$created_by,
        "updated at" = readable_time(tbl$updated_at),
        "updated by" = tbl$updated_by
      )
    } else if (tbl$data_source_format == "DELTASHARING") {
      info <- list(
        "table type" = tbl$table_type,
        "data source format" = tbl$data_source_format,
        "full name" = tbl$full_name,
        "owner" = tbl$owner,
        "storage location" = tbl$storage_location,
        "created at" = readable_time(tbl$created_at),
        "created by" = tbl$created_by,
        "updated at" = readable_time(tbl$updated_at),
        "updated by" = tbl$updated_by
      )
    } else {
      info <- list(
        "table type" = tbl$table_type,
        "data source format" = tbl$data_source_format,
        "full name" = tbl$full_name,
        "owner" = tbl$owner,
        "storage location" = tbl$storage_location,
        "created at" = readable_time(tbl$created_at),
        "created by" = tbl$created_by,
        "updated at" = readable_time(tbl$updated_at),
        "updated by" = tbl$updated_by,
        "last commit at" = readable_time(as.numeric(tbl$properties$delta.lastCommitTimestamp)),
        "min reader version" = tbl$properties$delta.minReaderVersion,
        "min writer version" = tbl$properties$delta.minWriterVersion
      )
    }
  } else {
    info <- purrr::map_chr(tbl$columns, function(x) {
      paste0(x$type_name, " (nullable: ", x$nullable, ")")
    })
    names(info) <- purrr::map_chr(tbl$columns, "name")
  }

  data.frame(
    name = names(info),
    type = unname(unlist(info))
  )

}

get_experiments <- function(host, token) {
  experiments <- db_experiments_list(host = host, token = token)
  exp_names <- purrr::map_chr(experiments, "name")
  exp_ids <-  purrr::map_chr(experiments, "experiment_id")
  data.frame(
    name = paste0(gsub(".*\\/(.*)", "\\1", exp_names), " (", exp_ids, ")"),
    type = "experiment"
  )
}

get_experiment <- function(id, host, token) {
  id <- get_id_from_panel_name(x = id)
  exp <- db_experiments_get(id = id, host = host, token = token)

  info <- list(
    "name" = exp$name,
    "experiment id" = exp$experiment_id,
    "artifact location" = exp$artifact_location,
    "user id" = exp$lifecycle_stage,
    "created at" = readable_time(exp$creation_time),
    "last updated" = readable_time(exp$last_update_time)
  )

  data.frame(
    name = names(info),
    type = unname(unlist(info))
  )
}


get_models <- function(host, token) {
  models <- db_mlflow_registered_models_list(
    max_results = 1000,
    host = host,
    token = token
  )
  models <- models$registered_models
  data.frame(
    name = purrr::map_chr(models, "name"),
    type = "model"
  )
}

get_model_metadata <- function(id, host, token) {
  model <- db_mlflow_registered_model_details(
    name = id,
    host = host,
    token = token
  )

  info <- list(
    "name" = model$name,
    "latest version" = model$latest_versions[[1]]$version,
    "user id" = model$user_id,
    "created at" = readable_time(model$creation_timestamp),
    "last updated" = readable_time(model$last_updated_timestamp),
    "permissions" = model$permission_level,
    "id" = model$id
  )

  data.frame(
    name = names(info),
    type = unname(unlist(info))
  )
}

get_model_versions <- function(id, host, token, version = NULL) {

  # if version is NULL get all, otherwise specific versions
  versions <- db_mlflow_registered_models_search_versions(
    name = id,
    host = host,
    token = token
  )[[1]]

  version_names <- purrr::map_chr(versions, function(x) {
    if (x$current_stage == "None") {
      x$version
    } else {
      paste0(x$version, " (", x$current_stage, ")")
    }
  })

  if (is.null(version)) {

    res <- data.frame(
      name = version_names,
      type = "version"
    )

  } else {

    version_meta <- versions[[which(version_names == version)]]

    info <- list(
      "current stage" = version_meta$current_stage,
      "created at" = readable_time(version_meta$creation_timestamp),
      "last updated" = readable_time(version_meta$last_updated_timestamp),
      "user id" = version_meta$user_id,
      "source" = version_meta$source,
      # can be missing, not sure worth including for now
      # "run id" = version_meta$run_id,
      "status" = version_meta$status
    )

    res <- data.frame(
      name = names(info),
      type = unname(unlist(info))
    )

  }

  res

}

get_clusters <- function(host, token) {
  clusters <- db_cluster_list(host = host, token = token)
  purrr::map_dfr(clusters, function(x) {
    list(
      name = as.character(glue::glue("[{x$state}] {x$cluster_name} ({x$cluster_id})")),
      type = "cluster"
    )
  })
}

get_cluster <- function(id, host, token) {
  x <- db_cluster_get(id, host, token)
  info <- list(
    "name" = x$cluster_name,
    "id" = id,
    "creator" = x$creator_user_name,
    "runtime" = x$spark_version,
    "worker node type" = x$node_type_id,
    "driver node type" = x$driver_node_type_id,
    "autotermination minutes" = x$autotermination_minutes,
    "start time" = readable_time(x$start_time),
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
  warehouses <- db_sql_warehouse_list(host = host, token = token)
  purrr::map_dfr(warehouses, function(x) {
    list(
      name = as.character(glue::glue("[{x$state}] {x$name} ({x$id})")),
      type = "warehouse"
    )
  })
}

get_warehouse <- function(id, host, token) {
  x <- db_sql_warehouse_get(id, host, token)
  info <- list(
    "name" = x$name,
    "id" = id,
    "creator" = x$creator_name,
    "channel" = dplyr::coalesce(x$channel$name, NA),
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
                         metastore = NULL,
                         catalog = NULL,
                         schema = NULL,
                         table = NULL,
                         modelregistry = NULL,
                         model = NULL,
                         versions = NULL,
                         columns = NULL,
                         experiments = NULL,
                         ...) {

  # uc metastore
  if (!is.null(metastore)) {

    if (!is.null(table)) {
      objects <- data.frame(
        name = c("metadata", "columns"),
        type = c("metadata", "columns")
      )
      return(objects)
    }

    if (!is.null(schema)) {
      objects <- get_tables(catalog = catalog, schema = schema, host = host, token = token)
      return(objects)
    }

    if (!is.null(catalog)) {
      objects <- get_schemas(catalog = catalog, host = host, token = token)
      return(objects)
    }

    # catch all, return catalogs
    objects <- get_catalogs(host = host, token = token)
    return(objects)

  }

  # experiments
  if (!is.null(experiments)) {
    objects <- get_experiments(host = host, token = token)
    return(objects)
  }

  # model registry
  if (!is.null(modelregistry)) {

    if (!is.null(versions)) {
      objects <- get_model_versions(id = model, host = host, token = token)
      return(objects)
    }

    if (!is.null(model)) {
      objects <- data.frame(
        name = c("metadata", "versions"),
        type = c("metadata", "versions")
      )
      return(objects)
    }

    # catch all to return models
    objects <- get_models(host = host, token = token)
    return(objects)

  }

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
  # first we should determine if workspace is single-tenant (no SQL/uc)

  # check if sql endpoint fails
  sql_active <- tryCatch(
    expr = {
      db_sql_warehouse_list(host = host, token = token)
      TRUE
    },
    error = function(e) FALSE
  )

  # check if UC catalogs endpoint fails
  uc_active <- tryCatch(
    expr = {
      db_uc_catalogs_list(host = host, token = token)
      TRUE
    },
    error = function(e) FALSE
  )

  info <- list(
    "Catalog" = "metastore",
    "Model Registry" = "modelregistry",
    "Experiments" = "experiments",
    "Clusters" = "clusters",
    "SQL Warehouses" = "warehouses",
    "File System (DBFS)" = "dbfs",
    "Workspace (Notebooks)" = "notebooks"
  )

  if (!sql_active) {
    info[["SQL Warehouses"]] <- NULL
  }

  if (!uc_active) {
    info[["Data"]] <- NULL
  }

  data.frame(
    name = names(info),
    type = unname(unlist(info))
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

  if ("model" %in% names(dots)) {
    if (leaf_type == "metadata") {
      info <- get_model_metadata(id = dots$model, host = host, token = token)
    } else if (leaf_type == "version") {
      info <- get_model_versions(
        id = dots$model,
        version = leaf$version,
        host = host,
        token = token
      )
    }
  }

  if ("table" %in% names(dots)) {
    info <- get_table_data(
      catalog = dots$catalog,
      schema = dots$schema,
      table = dots$table,
      host = host,
      token = token,
      metadata = leaf_type == "metadata"
    )
  }

  if (leaf_type == "experiment") {
    info <- get_experiment(
      id = leaf$experiment,
      host = host,
      token = token
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
                           model = NULL,
                           version = NULL,
                           experiment = NULL,
                           catalog = NULL,
                           schema = NULL,
                           table = NULL,
                           ...) {

  # explore data
  if (!is.null(catalog)) {
    path <- paste0(c(catalog, schema, table), collapse = "/")
    url <- glue::glue("{host}explore/data/{path}?o={db_wsid()}")
    return(utils::browseURL(url))
  }

  # version of model
  if (!is.null(version) && !is.null(model)) {
    version <- gsub("(\\d+) .*", "\\1", version)
    url <- glue::glue("{host}?o={db_wsid()}#mlflow/models/{model}/versions/{version}")
    return(utils::browseURL(url))
  }

  # model
  if (is.null(version) && !is.null(model)) {
    url <- glue::glue("{host}?o={db_wsid()}#mlflow/models/{model}")
    return(utils::browseURL(url))
  }

  # experiment
  if (!is.null(experiment)) {
    id <- get_id_from_panel_name(experiment)
    url <- glue::glue("{host}?o={db_wsid()}#mlflow/experiments/{id}")
    return(utils::browseURL(url))
  }

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
    content <- db_workspace_export(
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
    content <- db_dbfs_read(path = paste0(path, "/", files))

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
  # nocov start
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
          notebooks = dots$notebooks,
          metastore = dots$metastore,
          catalog = dots$catalog,
          schema = dots$schema,
          table = dots$table,
          columns = dots$columns,
          experiments = dots$experiments,
          modelregistry = dots$modelregistry,
          model = dots[["model"]],
          versions = dots$versions
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
  # nocov end
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

# nocov start
list_objects_types <- function() {
  list(
    workspace = list(contains = list(
      clusters = list(contains = list(
        cluster = list(
          icon = system.file("icons", "magnify.png", package = "brickster"),
          contains = "data"
        )
      )),
      metastore = list(contains = list(
        catalog = list(contains = list(
          schema = list(contains = list(
            table = list(contains = list(
              metadata = list(contains = "data"),
              columns = list(contains = "data")
            ))
          ))
        ))
      )),
      experiments = list(contains = list(
        experiment = list(
          icon = system.file("icons", "microscope.png", package = "brickster"),
          contains = "data"
        )
      )),
      modelregistry = list(contains = list(
        model = list(
          icon = system.file("icons", "abacus.png", package = "brickster"),
          contains = list(
            metadata = list(contains = "data"),
            versions = list(contains = list(
              version = list(
                icon = system.file("icons", "package.png", package = "brickster"),
                contains = "data"
              )
          ))
        ))
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
# nocov end
