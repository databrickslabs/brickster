#' Databricks SQL Connector (Python)
#'
#' @description  Access the Databricks SQL connector from Python via
#' `{reticulate}`.
#'
#' @details This requires that the connector has been installed via
#' [install_db_sql_connector()].
#'
#' For more documentation of the methods, refer to the
#' [python documentation](https://github.com/databricks/databricks-sql-python).
#'
#' @export
#' @keywords internal
py_db_sql_connector <- NULL

.onLoad <- function(libname, pkgname) {
  py_db_sql_connector <<- reticulate::import("databricks.sql", delay_load = TRUE)
  venv <- determine_brickster_venv()
  reticulate::use_virtualenv(virtualenv = venv, required = FALSE)
}
