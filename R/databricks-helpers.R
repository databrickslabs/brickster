on_databricks <- function() {
  dbr <- Sys.getenv("DATABRICKS_RUNTIME_VERSION")
  dbr != ""
}

#' Determine brickster virtualenv
#'
#' @details Returns `NULL` when running within Databricks,
#' otherwise `"r-brickster"`
#'
#' @export
determine_brickster_venv <- function() {
  if (on_databricks()) {
    NULL
  } else {
    "r-brickster"
  }
}
