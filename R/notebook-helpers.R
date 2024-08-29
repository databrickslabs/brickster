#' Detect if running within Databricks Notebook
#'
#' @details
#' R sessions on Databricks can be detected via various environment variables
#' and directories.
#'
#' @return Boolean
#' @export
in_databricks_nb <- function() {
  ("/databricks/spark/R/lib"  %in% .libPaths()) &&
    exists("DATABRICKS_GUID", envir = .GlobalEnv)
}
