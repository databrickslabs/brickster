# nocov start
dbi_connection_display_name <- function(connection) {
  warehouse <- db_sql_warehouse_get(
    id = connection@warehouse_id,
    host = connection@host,
    token = connection@token
  )
  glue::glue("{warehouse$name} ({connection@warehouse_id}) @ {connection@host}")
}

dbi_connection_code <- function(connection) {
  glue::glue(
    paste(
      "library(DBI)",
      "library(brickster)",
      "con <- dbConnect(",
      "  brickster::DatabricksSQL(),",
      "  warehouse_id = \"{connection@warehouse_id}\"",
      ")",
      sep = "\n"
    )
  )
}

dbi_list_object_types <- function(connection) {
  list(
    catalog = list(
      contains = list(
        schema = list(
          contains = list(
            table = list(
              contains = "data"
            )
          )
        )
      )
    )
  )
}

dbi_list_objects <- function(
  connection,
  catalog = NULL,
  schema = NULL,
  table = NULL,
  ...
) {
  host <- connection@host
  token <- connection@token
  if (is.null(catalog)) {
    return(get_catalogs(host = host, token = token))
  }

  if (is.null(schema)) {
    return(get_schemas(catalog = catalog, host = host, token = token))
  }

  if (!is.null(table)) {
    return(data.frame(name = NULL, type = NULL, check.names = FALSE))
  }

  get_tables(
    catalog = catalog,
    schema = schema,
    host = host,
    token = token
  )
}

dbi_list_columns <- function(
  connection,
  catalog = NULL,
  schema = NULL,
  table = NULL,
  ...
) {
  get_table_data(
    catalog = catalog,
    schema = schema,
    table = table,
    host = connection@host,
    token = connection@token,
    metadata = FALSE
  )
}

dbi_preview_object <- function(
  connection,
  rowLimit,
  catalog = NULL,
  schema = NULL,
  table = NULL,
  ...
) {
  name <- paste(
    DBI::dbQuoteIdentifier(connection, catalog),
    DBI::dbQuoteIdentifier(connection, schema),
    DBI::dbQuoteIdentifier(connection, table),
    sep = "."
  )

  sql <- paste0("SELECT * FROM ", name, " LIMIT ", as.integer(rowLimit))
  DBI::dbGetQuery(
    connection,
    sql,
    disposition = "INLINE",
    show_progress = FALSE
  )
}

dbi_connection_opened <- function(connection) {
  observer <- getOption("connectionObserver")
  if (is.null(observer)) {
    return(invisible(NULL))
  }

  observer$connectionOpened(
    type = "Databricks SQL",
    displayName = dbi_connection_display_name(connection),
    host = connection@host,
    icon = system.file("icons", "warehouse.png", package = "brickster"),
    connectCode = dbi_connection_code(connection),
    disconnect = function() {},
    listObjectTypes = function() {
      dbi_list_object_types(connection)
    },
    listObjects = function(...) {
      dbi_list_objects(connection, ...)
    },
    listColumns = function(...) {
      dbi_list_columns(connection, ...)
    },
    previewObject = function(rowLimit, ...) {
      dbi_preview_object(connection, rowLimit, ...)
    },
    actions = list(
      `Warehouse Monitoring` = list(
        icon = "",
        callback = function() {
          utils::browseURL(
            glue::glue(
              "https://{connection@host}/sql/warehouses/{connection@warehouse_id}/monitoring"
            )
          )
        }
      )
    ),
    connectionObject = connection
  )
}
# nocov end
