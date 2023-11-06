on_databricks <- function() {
  dbr <- Sys.getenv("DATABRICKS_RUNTIME_VERSION")
  dbr != ""
}

#' Detect brickster virtualenv
#'
#' @details Returns `NULL` when running within Databricks,
#' otherwise "r-brickster"
#'
#' @export
detect_brickster_venv <- function() {
  if (on_databricks()) {
    NULL
  } else {
    "r-brickster"
  }
}
