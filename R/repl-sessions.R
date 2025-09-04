#' List saved REPL contexts
#'
#' Returns saved execution contexts for the current Databricks workspace host.
#'
#' @inheritParams auth_params
#' @return data.frame
#' @export
db_repl_sessions <- function(host = db_host()) {
  df <- db_context_list(host = host)
  # if empty, return 0-row data.frame with expected cols
  if (is.null(df) || nrow(df) == 0) {
    return(data.frame(
      alias = character(),
      cluster_id = character(),
      context_id = character(),
      host = character(),
      language = character(),
      created_at = character(),
      stringsAsFactors = FALSE
    ))
  }
  df
}

#' Forget a saved REPL context
#'
#' Removes a saved alias. If `destroy = TRUE`, the remote context is also
#' destroyed (if it still exists).
#'
#' @param name Alias to remove
#' @param destroy If `TRUE`, also destroy the remote context
#' @inheritParams auth_params
#' @export
db_repl_forget <- function(
  name,
  destroy = FALSE,
  host = db_host(),
  token = db_token()
) {
  entry <- db_context_lookup(name, host = host)
  if (is.null(entry)) {
    cli::cli_abort("No saved context named {.val {name}} for this workspace.")
  }
  if (destroy) {
    # best-effort destroy
    try(
      {
        db_context_destroy(
          cluster_id = entry$cluster_id,
          context_id = entry$context_id,
          host = host,
          token = token
        )
      },
      silent = TRUE
    )
  }
  db_context_unregister(name, host = host)
  invisible(TRUE)
}
