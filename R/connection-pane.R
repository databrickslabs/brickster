# BACKLOG:
# - can only return so many objects at once, how to paginate via UI?
#   - impacts experiments, model registry, etc.

# nocov start
brickster_actions <- function(host) {
  list(
    `Open Workspace` = list(
      icon = "",
      callback = function() {
        utils::browseURL(glue::glue("https://{host}"))
      }
    )
  )
}
# nocov end

get_id_from_panel_name <- function(x) {
  sub(pattern = ".*\\((.*)\\).*", replacement = "\\1", x = x)
}

get_model_version_from_string <- function(x) {
  as.integer(sub(pattern = "(\\d+).*", replacement = "\\1", x = x))
}

readable_time <- function(x) {
  time <- as.POSIXct(
    x = x / 1000,
    origin = "1970-01-01",
    tz = "UTC"
  )
  as.character(time)
}

get_catalogs <- function(host, token) {
  catalogs <- db_uc_catalogs_list(host = host, token = token)
  data.frame(
    name = purrr::map_chr(catalogs, "name"),
    type = "catalog",
    check.names = FALSE
  )
  if (length(catalogs) > 0) {
    data.frame(
      name = purrr::map_chr(catalogs, "name"),
      type = "catalog",
      check.names = FALSE
    )
  } else {
    data.frame(name = NULL, type = NULL, check.names = FALSE)
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
      type = "schema",
      check.names = FALSE
    )
  } else {
    data.frame(name = NULL, type = NULL, check.names = FALSE)
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
      type = "table",
      check.names = FALSE
    )
  } else {
    data.frame(name = NULL, type = NULL, check.names = FALSE)
  }
}

get_uc_models <- function(catalog, schema, host, token) {
  models <- db_uc_models_list(
    catalog = catalog,
    schema = schema,
    host = host,
    token = token
  )
  if (length(models) > 0) {
    data.frame(
      name = purrr::map_chr(models, "name"),
      type = "model",
      check.names = FALSE
    )
  } else {
    data.frame(name = NULL, type = NULL, check.names = FALSE)
  }
}

get_uc_model <- function(catalog, schema, model, host, token) {
  model <- db_uc_models_get(
    catalog = catalog,
    schema = schema,
    model = model,
    host = host,
    token = token
  )
  info <- list(
    "name" = model$name,
    "owner" = model$owner,
    "created at" = readable_time(model$created_at),
    "created by" = model$created_by,
    "last updated" = readable_time(model$updated_at),
    "updated by" = model$updated_by,
    "id" = model$id
  )

  data.frame(
    name = names(info),
    type = unname(unlist(info)),
    check.names = FALSE
  )
}

get_uc_model_versions <- function(catalog, schema, model, host, token,
                                  version = NULL) {

  # if version is NULL get all, otherwise specific versions
  versions <- db_uc_model_versions_get(
    catalog,
    schema,
    model,
    host = host,
    token = token
  )[[1]]

  # get model info again to get the aliases
  model_info <- db_uc_models_get(catalog, schema, model, host, token)

  aliases <- purrr::map(
    model_info$aliases, ~{
      setNames(.x$version_num, .x$alias_name)
    }) |>
    unlist()

  version_names <- purrr::map_chr(versions, function(x) {
    if (x$version %in% aliases) {
      alias_values <- names(aliases[x$version %in% aliases])
      alias_part <- paste0("@", alias_values, collapse = ", ")
      paste0(x$version, " (", alias_part, ")")
    } else {
      x$version
    }
  })

  if (is.null(version)) {

    res <- data.frame(
      name = version_names,
      type = "version",
      check.names = FALSE
    )

  } else {
    version_meta <- versions[[which(purrr::map_vec(versions, "version") == version)]]
    info <- list(
      "created at" = readable_time(version_meta$created_at),
      "created by" = version_meta$created_by,
      "last updated" = readable_time(version_meta$updated_at),
      "updated by" = version_meta$updated_by,
      "run id" = version_meta$run_id,
      "run workspace id" = version_meta$run_workspace_id,
      "source" = version_meta$source,
      "status" = version_meta$status,
      "id" = version_meta$id
    )

    res <- data.frame(
      name = names(info),
      type = unname(unlist(info)),
      check.names = FALSE
    )

  }

  res

}

get_uc_functions <- function(catalog, schema, host, token) {
  funcs <- db_uc_funcs_list(
    catalog = catalog,
    schema = schema,
    host = host,
    token = token
  )
  if (length(funcs) > 0) {
    data.frame(
      name = purrr::map_chr(funcs, "name"),
      type = "func",
      check.names = FALSE
    )
  } else {
    data.frame(name = NULL, type = NULL, check.names = FALSE)
  }
}

get_uc_function <- function(catalog, schema, func, host, token) {
  func <- db_uc_funcs_get(
    catalog = catalog,
    schema = schema,
    func = func,
    host = host,
    token = token
  )
  info <- list(
    "name" = func$name,
    "date type" = func$data_type,
    "full data type" = func$full_data_type,
    "created at" = readable_time(func$created_at),
    "created by" = func$created_by,
    "last updated" = readable_time(func$updated_at),
    "updated by" = func$updated_by,
    "id" = func$function_id
  )

  data.frame(
    name = names(info),
    type = unname(unlist(info)),
    check.names = FALSE
  )
}

get_uc_volumes <- function(catalog, schema, host, token) {
  volumes <- db_uc_volumes_list(
    catalog = catalog,
    schema = schema,
    host = host,
    token = token
  )
  if (length(volumes) > 0) {
    data.frame(
      name = purrr::map_chr(volumes, "name"),
      type = "volume",
      check.names = FALSE
    )
  } else {
    data.frame(name = NULL, type = NULL, check.names = FALSE)
  }
}

get_uc_volume <- function(catalog, schema, host, volume, token) {
  volumes <- db_uc_volumes_list(
    catalog = catalog,
    schema = schema,
    host = host,
    token = token
  )

  volume <- purrr::keep(volumes, ~.x$name == volume)[[1]]

  info <- list(
    "name" = volume$name,
    "volume type" = volume$volume_type,
    "storage location" = volume$storage_location,
    "created at" = readable_time(volume$created_at),
    "created by" = volume$created_by,
    "last updated" = readable_time(volume$updated_at),
    "updated by" = volume$updated_by,
    "id" = volume$volume_id
  )

  data.frame(
    name = names(info),
    type = unname(unlist(info)),
    check.names = FALSE
  )
}

get_schema_objects <- function(catalog, schema, host, token) {

  objects <- list()
  objects$tables <- get_tables(catalog, schema, host, token)
  objects$volumes <- get_uc_volumes(catalog, schema, host, token)
  objects$models <- get_uc_models(catalog, schema, host, token)
  objects$funcs <- get_uc_functions(catalog, schema, host, token)

  # how many objects of each type exist
  # only show when objects exist within
  sizes <- purrr::map_int(objects, nrow) |>
    purrr::keep(~.x > 0) |>
    purrr::imap_chr(~ glue::glue("{.y} ({.x})"))

  data.frame(
    name = unname(sizes),
    type = names(sizes),
    check.names = FALSE
  )

}

get_table_data <- function(catalog, schema, table, host, token, metadata = TRUE) {
  # if metadata is TRUE then return metadata, otherwise columns
  tbl <- db_uc_tables_get(
    catalog = catalog,
    schema = schema,
    table = table,
    omit_columns = FALSE,
    omit_properties = FALSE,
    omit_username = FALSE,
    host = host,
    token = token
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
    } else if (tbl$data_source_format == "VECTOR_INDEX_FORMAT") {
      info <- list(
        "table type" = tbl$table_type,
        "data source format" = tbl$data_source_format,
        "full name" = tbl$full_name,
        "owner" = tbl$owner,
        "endpoint name" = tbl$properties$endpoint_name,
        "endpoint type" = tbl$properties$endpoint_type,
        "primary key" = tbl$properties$primary_key,
        "created at" = readable_time(tbl$created_at),
        "created by" = tbl$created_by,
        "updated at" = readable_time(tbl$updated_at),
        "updated by" = tbl$updated_by
      )
    } else if (tbl$data_source_format == "TABLE") {
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
    } else {
      info <- list(
        "table type" = tbl$table_type,
        "data source format" = tbl$data_source_format,
        "full name" = tbl$full_name,
        "owner" = tbl$owner,
        "created at" = readable_time(tbl$created_at),
        "created by" = tbl$created_by,
        "updated at" = readable_time(tbl$updated_at),
        "updated by" = tbl$updated_by
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
    type = unname(unlist(info)),
    check.names = FALSE
  )

}

get_experiments <- function(host, token) {
  experiments <- db_experiments_list(host = host, token = token)
  exp_names <- purrr::map_chr(experiments, "name")
  exp_ids <-  purrr::map_chr(experiments, "experiment_id")
  data.frame(
    name = paste0(gsub(".*\\/(.*)", "\\1", exp_names), " (", exp_ids, ")"),
    type = "experiment",
    check.names = FALSE
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
    type = unname(unlist(info)),
    check.names = FALSE
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
    type = "model",
    check.names = FALSE
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
    type = unname(unlist(info)),
    check.names = FALSE
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
      type = "version",
      check.names = FALSE
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
      type = unname(unlist(info)),
      check.names = FALSE
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
    "# workers" = x$num_workers %||% 0L,
    "cores" = x$cluster_cores %||% 0L,
    "memory (mb)" = x$cluster_memory_mb %||% 0L
  )
  data.frame(
    name = names(info),
    type = unname(unlist(info)),
    check.names = FALSE
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
    type = unname(unlist(info)),
    check.names = FALSE
  )
}

# nocov start
list_objects <- function(host, token,
                         type = NULL,
                         workspace = NULL,
                         clusters = NULL,
                         warehouses = NULL,
                         metastore = NULL,
                         catalog = NULL,
                         schema = NULL,
                         tables = NULL,
                         table = NULL,
                         volumes = NULL,
                         funcs = NULL,
                         models = NULL,
                         modelregistry = NULL,
                         model = NULL,
                         versions = NULL,
                         columns = NULL,
                         experiments = NULL,
                         ...) {

  # uc metastore
  if (!is.null(metastore)) {

    if (!is.null(schema)) {

      if (!is.null(volumes)) {
        objects <- get_uc_volumes(catalog, schema, host, token)
        return(objects)
      }

      if (!is.null(funcs)) {
        objects <- get_uc_functions(catalog, schema, host, token)
        return(objects)
      }

      if (!is.null(models)) {

        if (!is.null(versions)) {
          objects <- get_uc_model_versions(catalog, schema, model, host, token)
          return(objects)
        }

        if (!is.null(model)) {
          objects <- data.frame(
            name = c("metadata", "versions"),
            type = c("metadata", "versions"),
            check.names = FALSE
          )
          return(objects)
        }

        objects <- get_uc_models(catalog, schema, host, token)
        return(objects)
      }

      if (!is.null(tables)) {

        if (!is.null(table)) {
          objects <- data.frame(
            name = c("metadata", "columns"),
            type = c("metadata", "columns"),
            check.names = FALSE
          )
          return(objects)
        }

        objects <- get_tables(catalog, schema, host, token)
        return(objects)
      }

      objects <- get_schema_objects(catalog, schema, host, token)

      return(objects)
    }

    if (!is.null(catalog)) {
      objects <- get_schemas(catalog, host, token)
      return(objects)
    }

    # catch all, return catalogs
    objects <- get_catalogs(host, token)
    return(objects)

  }

  # experiments
  if (!is.null(experiments)) {
    objects <- get_experiments(host, token)
    return(objects)
  }

  # model registry
  if (!is.null(modelregistry)) {

    if (!is.null(versions)) {
      objects <- get_model_versions(id = model, host, token)
      return(objects)
    }

    if (!is.null(model)) {
      objects <- data.frame(
        name = c("metadata", "versions"),
        type = c("metadata", "versions"),
        check.names = FALSE
      )
      return(objects)
    }

    # catch all to return models
    objects <- get_models(host, token)
    return(objects)

  }

  # clusters
  if (!is.null(clusters)) {
    objects <- get_clusters(host, token)
    return(objects)
  }

  # warehouses
  if (!is.null(warehouses)) {
    objects <- get_warehouses(host, token)
    return(objects)
  }

  # baseline view (static)
  # first we should determine if workspace is single-tenant (no SQL/uc)

  # check if sql endpoint fails
  sql_active <- tryCatch(
    expr = {
      db_sql_warehouse_list(host, token)
      TRUE
    },
    error = function(e) FALSE
  )

  # check if UC catalogs endpoint fails
  uc_active <- tryCatch(
    expr = {
      db_uc_catalogs_list(host, token)
      TRUE
    },
    error = function(e) FALSE
  )

  info <- list(
    "Catalog" = "metastore",
    "Model Registry" = "modelregistry",
    "Experiments" = "experiments",
    "Clusters" = "clusters",
    "SQL Warehouses" = "warehouses"
  )

  if (!sql_active) {
    info[["SQL Warehouses"]] <- NULL
  }

  if (!uc_active) {
    info[["Data"]] <- NULL
  }

  data.frame(
    name = names(info),
    type = unname(unlist(info)),
    check.names = FALSE
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

  if (!is.null(dots$modelregistry) && "model" %in% names(dots)) {
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

  if (!is.null(dots$catalog) && "model" %in% names(dots)) {
    if (leaf_type == "metadata") {
      info <- get_uc_model(
        catalog = dots[["catalog"]],
        schema = dots[["schema"]],
        model = dots[["model"]],
        host = host,
        token = token
      )
    } else if (leaf_type == "version") {
      info <- get_uc_model_versions(
        catalog = dots[["catalog"]],
        schema = dots[["schema"]],
        model = dots[["model"]],
        version = get_model_version_from_string(leaf$version),
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

  if (leaf_type == "func") {
    info <- get_uc_function(
      catalog = dots$catalog,
      schema = dots$schema,
      func = dots$func,
      host = host,
      token = token
    )
  }

  if (leaf_type == "volume") {
    info <- get_uc_volume(
      catalog = dots$catalog,
      schema = dots$schema,
      volume = leaf$volume,
      host = host,
      token = token
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
                           model = NULL,
                           version = NULL,
                           experiment = NULL,
                           catalog = NULL,
                           schema = NULL,
                           table = NULL,
                           func = NULL,
                           volume = NULL,
                           ...) {

  ws_id <- db_current_workspace_id()

  if (!is.null(catalog)) {

    if (!is.null(catalog) && !is.null(schema) && !is.null(func)) {
      path <- paste0(c("functions", catalog, schema, func), collapse = "/")
    } else if (!is.null(catalog) && !is.null(schema) && !is.null(model) && !is.null(version)) {
      version <- get_model_version_from_string(version)
      path <- paste0(c("models", catalog, schema, model, "version", version), collapse = "/")
    } else if (!is.null(catalog) && !is.null(schema) && !is.null(model)) {
      path <- paste0(c("models", catalog, schema, model), collapse = "/")
    } else if (!is.null(catalog) && !is.null(schema) && !is.null(volume)) {
      path <- paste0(c("volumes", catalog, schema, volume), collapse = "/")
    } else if (!is.null(catalog) && !is.null(schema) && !is.null(table)) {
      path <- paste0(c(catalog, schema, table), collapse = "/")
    } else if (!is.null(catalog) && !is.null(schema)) {
      path <- paste0(c(catalog, schema), collapse = "/")
    } else {
      path <- catalog
    }

    url <- glue::glue("https://{host}/explore/data/{path}?o={ws_id}")
    return(utils::browseURL(url))

  }

  # version of model
  if (!is.null(version) && !is.null(model)) {
    version <- gsub("(\\d+) .*", "\\1", version)
    url <- glue::glue("https://{host}/?o={ws_id}#mlflow/models/{model}/versions/{version}")
    return(utils::browseURL(url))
  }

  # model
  if (is.null(version) && !is.null(model)) {
    url <- glue::glue("https://{host}/ml/models/{model}?o={ws_id}")
    return(utils::browseURL(url))
  }

  # experiment
  if (!is.null(experiment)) {
    id <- get_id_from_panel_name(experiment)
    url <- glue::glue("https://{host}/?o={ws_id}#mlflow/experiments/{id}")
    return(utils::browseURL(url))
  }

  if (!is.null(cluster)) {
    id <- get_id_from_panel_name(cluster)
    url <- glue::glue("https://{host}/?o={ws_id}#setting/clusters/{id}/configuration")
    return(utils::browseURL(url))
  }

  if (!is.null(warehouse)) {
    id <- get_id_from_panel_name(warehouse)
    url <- glue::glue("https://{host}/sql/warehouses/{id}")
    return(utils::browseURL(url))
  }

}
# nocov end

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

        objects <- list_objects(
          host,
          token,
          files = dots[["files"]],
          warehouses = dots[["warehouses"]],
          clusters = dots[["clusters"]],
          metastore = dots[["metastore"]],
          catalog = dots[["catalog"]],
          schema = dots[["schema"]],
          table = dots[["table"]],
          tables = dots[["tables"]],
          volume = dots[["volume"]],
          volumes = dots[["volumes"]],
          models = dots[["models"]],
          func = dots[["func"]],
          funcs = dots[["funcs"]],
          columns = dots[["columns"]],
          experiments = dots[["experiments"]],
          modelregistry = dots[["modelregistry"]],
          model = dots[["model"]],
          versions = dots[["versions"]]
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
      clusters = list(
        icon = system.file("icons", "compute.png", package = "brickster"),
        contains = list(
        cluster = list(
          icon = system.file("icons", "open.png", package = "brickster"),
          contains = "data"
        )
      )),
      metastore = list(
        icon = system.file("icons", "metastore.png", package = "brickster"),
        contains = list(
        catalog = list(
          icon = system.file("icons", "catalog.png", package = "brickster"),
          contains = list(
          schema = list(
            icon = system.file("icons", "schema.png", package = "brickster"),
            contains = list(
            tables = list(contains = list(
              table = list(
                icon = system.file("icons", "table.png", package = "brickster"),
                contains = list(
                metadata = list(
                  icon = system.file("icons", "open.png", package = "brickster"),
                  contains = "data"
                ),
                columns = list(
                  contains = "data"
                )
              ))
            )),
            volumes = list(contains = list(
              volume = list(
                icon = system.file("icons", "volume.png", package = "brickster"),
                contains = "data"
              )
            )),
            models = list(
              contains = list(
              model = list(
                icon = system.file("icons", "model.png", package = "brickster"),
                contains = list(
                  metadata = list(contains = "data"),
                  versions = list(contains = list(
                    version = list(
                      icon = system.file("icons", "open.png", package = "brickster"),
                      contains = "data"
                    )
                  ))
                ))
            )),
            funcs = list(contains = list(
              func = list(
                icon = system.file("icons", "func.png", package = "brickster"),
                contains = "data"
              )
            ))
          ))
        ))
      )),
      experiments = list(
        icon = system.file("icons", "exp.png", package = "brickster"),
        contains = list(
        experiment = list(
          icon = system.file("icons", "open.png", package = "brickster"),
          contains = "data"
        )
      )),
      modelregistry = list(
        icon = system.file("icons", "model.png", package = "brickster"),
        contains = list(
        model = list(contains = list(
            metadata = list(contains = "data"),
            versions = list(contains = list(
              version = list(
                icon = system.file("icons", "open.png", package = "brickster"),
                contains = "data"
              )
          ))
        ))
      )),
      warehouses = list(
        icon = system.file("icons", "warehouse.png", package = "brickster"),
        contains = list(
        warehouse = list(
          icon = system.file("icons", "open.png", package = "brickster"),
          contains = "data"
        )
      ))
    ))
  )
}
# nocov end
