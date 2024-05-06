on_databricks <- function() {
  dbr <- Sys.getenv("DATABRICKS_RUNTIME_VERSION")
  dbr != ""
}

in_databricks_nb <- function() {
  ("/databricks/spark/R/lib"  %in% .libPaths()) &&
    exists("DATABRICKS_GUID", envir = .GlobalEnv)
}

use_posit_repo <- function() {
  if (in_databricks_nb()) {
    codename <- system("lsb_release -c --short", intern = T)
    mirror <- paste0("https://packagemanager.posit.co/cran/__linux__/", codename, "/latest")
    options(repos = c(POSIT = mirror))
  }
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
