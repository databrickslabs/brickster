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
    lib_path <- fs::path(path, rver)
  } else {
    lib_path <- fs::path(path)
  }

  lib_path <- fs::path_expand(lib_path)

  # ensure directory exists
  fs::dir_create(lib_path, recurse = TRUE)
  lib_path <- fs::path_real(lib_path)

  cli::cli_alert_info("Primary package path is now {.path {lib_path}}")
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
    lib_path <- fs::path(path, rver)
  } else {
    lib_path <- fs::path(path)
  }

  lib_path <- fs::path_expand(lib_path)
  if (fs::dir_exists(lib_path) || fs::file_exists(lib_path)) {
    lib_path <- fs::path_real(lib_path)
  } else {
    lib_path <- fs::path_norm(lib_path)
  }
  .libPaths(new = setdiff(.libPaths(), lib_path))
}
