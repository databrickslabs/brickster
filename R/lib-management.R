# functions for managing libraries on databricks

#' Add Library Path
#'
#' @param path Directory that will added as location for which packages
#' are searched. Recursively creates the directory if it doesn't exist. On
#' Databricks remember to use `/dbfs/` or `/Volumes/...` as a prefix.
#' @param after Location at which to append the `path` value after.
#' @param version If `TRUE` will add the R version string to the end
#' of `path`. This is recommended if using different R versions and sharing a
#' common `path` between users.
#'
#' @details
#' This functions primary use is when using Databricks notebooks or hosted
#' RStudio, however, it works anywhere.
#'
#' @seealso [base::.libPaths()], [remove_lib_path()]
#'
#' @export
add_lib_path <- function(path, after, version = FALSE) {
  if (version) {
    rver <- getRversion()
    lib_path <- file.path(path, rver)
  } else {
    lib_path <- file.path(path)
  }

  # ensure directory exists
  if (!file.exists(lib_path)) {
    dir.create(lib_path, recursive = TRUE)
  }

  lib_path <- normalizePath(lib_path, "/")

  message("primary package path is now ", lib_path)
  .libPaths(new = append(.libPaths(), lib_path, after = after))
  lib_path
}

#' Remove Library Path
#'
#' @param path Directory to remove from [.libPaths()].
#' @param version If `TRUE` will add the R version string to the end
#' of `path` before removal.
#'
#' @seealso [base::.libPaths()], [remove_lib_path()]
#' @export
remove_lib_path <- function(path, version = FALSE) {
  if (version) {
    rver <- getRversion()
    lib_path <- file.path(path, rver)
  } else {
    lib_path <- file.path(path)
  }

  lib_path <- normalizePath(lib_path, "/")
  .libPaths(new = setdiff(.libPaths(), lib_path))
}
