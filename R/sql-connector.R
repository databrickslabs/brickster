#' Install Databricks SQL Connector (Python)
#'
#' @inheritParams reticulate::py_install
#' @details Installs [`databricks-sql-connector`](https://github.com/databricks/databricks-sql-python).
#' Environemnt is resolved by [determine_brickster_venv()] which defaults to
#' `r-brickster` virtualenv.
#'
#' When running within Databricks it will use the existing python environment.
#'
#' @export
#'
#' @examples
#' \dontrun{install_db_sql_connector()}
install_db_sql_connector <- function(envname = determine_brickster_venv(),
                                     method = "auto", ...) {
  reticulate::py_install(
    "databricks-sql-connector",
    envname = envname,
    method = method,
    ...
  )
}

#' Create Databricks SQL Connector Client
#'
#' @details TODO
#'
#' @param id TODO
#' @param catalog TODO
#' @param schema TODO
#' @param compute_type TODO
#' @param use_cloud_fetch TODO
#' @param session_configuration TODO
#' @param host TODO
#' @param token TODO
#' @param workspace_id TODO
#'
#' @return TODO
#' @import arrow
#'
#' @examples
#' \dontrun{
#'   client <- db_sql_client(id = "<warehouse_id>", use_cloud_fetch = TRUE)
#' }
db_sql_client <- function(id,
                          catalog = NULL, schema = NULL,
                          compute_type = c("warehouse", "cluster"),
                          use_cloud_fetch = FALSE,
                          session_configuration = list(),
                          host = db_host(), token = db_token(),
                          workspace_id = db_wsid(),
                          ...) {

  compute_type <- match.arg(compute_type)
  http_path <- generate_http_path(
    id = id,
    is_warehouse = compute_type == "warehouse",
    workspace_id = workspace_id
  )

  DatabricksSqlClient$new(
    host = host,
    token = token,
    http_path = http_path,
    catalog = catalog,
    schema = schema,
    use_cloud_fetch = use_cloud_fetch,
    session_configuration = session_configuration,
    ...
  )

}

DatabricksSqlClient <- R6::R6Class(
  classname = "db_sql_client",
  public = list(

    initialize = function(host, token, http_path,
                          catalog, schema,
                          use_cloud_fetch, session_configuration,
                          ...) {

      private$connection <- py_db_sql_connector$connect(
        server_hostname = host,
        access_token = token,
        http_path = http_path,
        use_cloud_fetch = use_cloud_fetch,
        session_configuration = session_configuration,
        ...
      )
    },

    columns = function(catalog_name = NULL, schema_name = NULL,
                       table_name = NULL, column_name = NULL,
                       as_tibble = TRUE) {
      cursor <- private$connection$cursor()
      on.exit(cursor$close())
      cursor$columns(
        catalog_name = catalog_name,
        schema_name = schema_name,
        table_name = table_name,
        column_name = column_name
      )
      handle_results(cursor$fetchall_arrow(), as_tibble)
    },

    catalogs = function(as_tibble = TRUE) {
      cursor <- private$connection$cursor()
      on.exit(cursor$close())
      cursor$catalogs()
      handle_results(cursor$fetchall_arrow(), as_tibble)
    },

    schemas = function(catalog_name = NULL, schema_name = NULL,
                       as_tibble = TRUE) {
      cursor <- private$connection$cursor()
      on.exit(cursor$close())
      cursor$schemas(
        catalog_name = catalog_name,
        schema_name = schema_name
      )
      handle_results(cursor$fetchall_arrow(), as_tibble)
    },

    tables = function(catalog_name = NULL, schema_name = NULL,
                      table_name = NULL, table_types = NULL,
                      as_tibble = TRUE) {
      cursor <- private$connection$cursor()
      on.exit(cursor$close())
      cursor$tables(
        catalog_name = catalog_name,
        schema_name = schema_name,
        table_name = table_name,
        table_types = table_types
      )
      handle_results(cursor$fetchall_arrow(), as_tibble)
    },

    execute = function(operation, parameters = NULL, as_tibble = TRUE) {
      cursor <- private$connection$cursor()
      on.exit(cursor$close())
      cursor$execute(
        operation = operation,
        parameters = parameters
      )
      handle_results(cursor$fetchall_arrow(), as_tibble)
    },

    execute_many = function(operation, seq_of_parameters = NULL,
                            as_tibble = TRUE) {
      cursor <- private$connection$cursor()
      on.exit(cursor$close())
      cursor$executemany(
        operation = operation,
        seq_of_parameters = seq_of_parameters
      )
      handle_results(cursor$fetchall_arrow(), as_tibble)
    }

  ),
  private = list(
    connection = NULL,

    finalize = function() {
      private$connection$close()
    }
  )
)

generate_http_path <- function(id, is_warehouse = TRUE,
                               workspace_id = db_wsid()) {
  if (is_warehouse) {
    paste0("/sql/1.0/warehouses/", id)
  } else {
    paste0("/sql/protocolv1/o/", workspace_id, "/", id)
  }
}

handle_results <- function(x, as_tibble) {
  if (as_tibble) {
    x <- dplyr::collect(x)
  }
  x
}

