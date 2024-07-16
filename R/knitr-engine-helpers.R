# nocov start
#' Setup Databricks RMarkdown
#'
#' @param cluster_id Databricks cluster ID
#'
#' @details
#' This function should be run in an RMarkdown setup chunk to allow subsequent
#' chunks to use `databricks_*` related knitr engines that allow remote
#' execution against a Databricks cluster.
#'
#' This function deliberately does not have parameters to accept credentials
#' (host/token). These credentials should be managed elsewhere (e.g. `.Renviron`)
#' and not stored in plain-text within the script or markdown.
#'
#' @return Databricks execution context ID
#' @export
setup_databricks_rmd <- function(cluster_id) {

  # NOTE:
  # deliberately does not accept host/token interactively
  # credentials should not be used in rmarkdown content as plain text

  # get and start cluster
  get_and_start_cluster(
    cluster_id = cluster_id
  )

  # create execution context
  exec_context <- db_context_create(
    cluster_id = cluster_id,
    language = "r"
  )

  # set chunk options
  # these are databricks specific and required in order to hook into execution
  # context on cluster
  knitr::opts_chunk$set(db_cluster_id = cluster_id)
  knitr::opts_chunk$set(db_exec_context = exec_context$id)

  invisible(exec_context)
}
# nocov end
