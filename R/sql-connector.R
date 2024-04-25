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
#' @details Create client using Databricks SQL Connector.
#'
#' @param id String, ID of either the SQL warehouse or all purpose cluster.
#' Important to set `compute_type` to the associated type of `id`.
#' @param compute_type One of `"warehouse"` (default) or `"cluster"`, corresponding to
#' associated compute type of the resource specified in `id`.
#' @param use_cloud_fetch Boolean (default is `FALSE`). `TRUE` to send fetch
#' requests directly to the cloud object store to download chunks of data.
#' False to send fetch requests directly to Databricks.
#'
#' If `use_cloud_fetch` is set to `TRUE` but network access is blocked, then
#' the fetch requests will fail.
#' @param session_configuration A optional named list of Spark session
#' configuration parameters. Setting a configuration is equivalent to using the
#' `SET key=val` SQL command.
#' Run the SQL command `SET -v` to get a full list of available configurations.
#' @param workspace_id String, workspace Id used to build the http path for the
#' connection. This defaults to using [db_wsid()] to get `DATABRICKS_WSID`
#' environment variable. Not required if `compute_type` is `"cluster"`.
#' @param ... passed onto [DatabricksSqlClient()].
#' @inheritParams db_sql_exec_query
#' @inheritParams auth_params
#'
#' @import arrow
#' @returns [DatabricksSqlClient()]
#' @examples
#' \dontrun{
#'   client <- db_sql_client(id = "<warehouse_id>", use_cloud_fetch = TRUE)
#' }
#' @export
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

#' @title Databricks SQL Connector
#'
#' @description
#' Wraps the [`databricks-sql-connector`](https://github.com/databricks/databricks-sql-python)
#' using [reticulate](https://rstudio.github.io/reticulate/).
#'
#' [API reference on Databricks docs](https://docs.databricks.com/en/dev-tools/python-sql-connector.html#api-reference)
#' @import R6
#' @export
DatabricksSqlClient <- R6::R6Class(
  classname = "db_sql_client",
  public = list(

    #' @description
    #' Creates a new instance of this [R6][R6::R6Class] class.
    #'
    #' Note that this object is typically constructed via [db_sql_client()].
    #'
    #' @param host (`character(1)`)\cr
    #'   See [db_sql_client()].
    #' @param token (`character(1)`)\cr
    #'   See [db_sql_client()].
    #' @param http_path (`character(1)`)\cr
    #'   See [db_sql_client()].
    #' @param catalog (`character(1)`)\cr
    #'   See [db_sql_client()].
    #' @param use_cloud_fetch (`logical(1)`)\cr
    #'   See [db_sql_client()].
    #' @param session_configuration (`list(...)`)\cr
    #'   See [db_sql_client()].
    #' @param ... Parameters passed to [connection method](https://docs.databricks.com/en/dev-tools/python-sql-connector.html#methods)
    #' @return [DatabricksSqlClient].
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

    #' @description
    #' Execute a metadata query about the columns.
    #'
    #' @param catalog_name (`character(1)`)\cr
    #'   A catalog name to retrieve information about.
    #'   The `%` character is interpreted as a wildcard.
    #' @param schema_name (`character(1)`)\cr
    #'   A schema name to retrieve information about.
    #'   The `%` character is interpreted as a wildcard.
    #' @param table_name (`character(1)`)\cr
    #'   A table name to retrieve information about.
    #'   The `%` character is interpreted as a wildcard.
    #' @param column_name (`character(1)`)\cr
    #'   A column name to retrieve information about.
    #'   The `%` character is interpreted as a wildcard.
    #' @param as_tibble (`logical(1)`)\cr
    #'   If `TRUE` (default) will return [tibble::tibble], otherwise returns
    #'   [arrow::Table].
    #' @examples
    #' \dontrun{
    #'   client$columns(catalog_name = "defa%")
    #'   client$columns(catalog_name = "default", table_name = "gold_%")
    #' }
    #' @return [tibble::tibble] or [arrow::Table].
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

    #' @description
    #' Execute a metadata query about the catalogs.
    #'
    #' @param as_tibble (`logical(1)`)\cr
    #'   If `TRUE` (default) will return [tibble::tibble], otherwise returns
    #'   [arrow::Table].
    #' @examples
    #' \dontrun{
    #'   client$catalogs()
    #' }
    #' @return [tibble::tibble] or [arrow::Table].
    catalogs = function(as_tibble = TRUE) {
      cursor <- private$connection$cursor()
      on.exit(cursor$close())
      cursor$catalogs()
      handle_results(cursor$fetchall_arrow(), as_tibble)
    },

    #' @description
    #' Execute a metadata query about the schemas.
    #'
    #' @param catalog_name (`character(1)`)\cr
    #'   A catalog name to retrieve information about.
    #'   The `%` character is interpreted as a wildcard.
    #' @param schema_name (`character(1)`)\cr
    #'   A schema name to retrieve information about.
    #'   The `%` character is interpreted as a wildcard.
    #' @param as_tibble (`logical(1)`)\cr
    #'   If `TRUE` (default) will return [tibble::tibble], otherwise returns
    #'   [arrow::Table].
    #' @examples
    #' \dontrun{
    #'   client$schemas(catalog_name = "main")
    #' }
    #' @return [tibble::tibble] or [arrow::Table].
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

    #' @description
    #' Execute a metadata query about tables and views
    #'
    #' @param catalog_name (`character(1)`)\cr
    #'   A catalog name to retrieve information about.
    #'   The `%` character is interpreted as a wildcard.
    #' @param schema_name (`character(1)`)\cr
    #'   A schema name to retrieve information about.
    #'   The `%` character is interpreted as a wildcard.
    #' @param table_name (`character(1)`)\cr
    #'   A table name to retrieve information about.
    #'   The `%` character is interpreted as a wildcard.
    #' @param table_types (`character()`)\cr
    #'   A list of table types to match, for example `"TABLE"` or `"VIEW"`.
    #' @param as_tibble (`logical(1)`)\cr
    #'   If `TRUE` (default) will return [tibble::tibble], otherwise returns
    #'   [arrow::Table].
    #' @return [tibble::tibble] or [arrow::Table].
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

    #' @description
    #' Prepares and then runs a database query or command.
    #'
    #' @param operation (`character(1)`)\cr
    #'   The query or command to prepare and then run.
    #' @param parameters (`list()`)\cr
    #'   Optional. A sequence of parameters to use with the operation parameter.
    #' @param as_tibble (`logical(1)`)\cr
    #'   If `TRUE` (default) will return [tibble::tibble], otherwise returns
    #'   [arrow::Table].
    #' @examples
    #' \dontrun{
    #'  client$execute("select 1")
    #'  client$execute("select * from x.y.z limit 100")
    #'  client$execute(
    #'    operation = "select * from x.y.z where a < %(threshold)s limit 1000",
    #'    parameters = list(threshold = 100)
    #'  )
    #'}
    #' @return [tibble::tibble] or [arrow::Table].
    execute = function(operation, parameters = NULL, as_tibble = TRUE) {
      cursor <- private$connection$cursor()
      on.exit(cursor$close())
      cursor$execute(
        operation = operation,
        parameters = parameters
      )
      handle_results(cursor$fetchall_arrow(), as_tibble)
    },

    #' @description
    #' Prepares and then runs a database query or command using all parameter
    #' sequences in the seq_of_parameters argument. Only the final result set
    #' is retained.
    #'
    #' @param operation (`character(1)`)\cr
    #'   The query or command to prepare and then run.
    #' @param seq_of_parameters (`list(list())`)\cr
    #'   A sequence of many sets of parameter values to use with the operation
    #'   parameter.
    #' @param as_tibble (`logical(1)`)\cr
    #'   If `TRUE` (default) will return [tibble::tibble], otherwise returns
    #'   [arrow::Table].
    #' @examples
    #' \dontrun{
    #'  client$execute_many(
    #'    operation = "select * from x.y.z where a < %(threshold)s limit 1000",
    #'    seq_of_parameters = list(
    #'      list(threshold = 100),
    #'      list(threshold = 200),
    #'      list(threshold = 300)
    #'    )
    #'  )
    #'}
    #' @return [tibble::tibble] or [arrow::Table].
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
