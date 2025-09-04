# Context registry helpers (internal)

# nocov start

#' Context Registry Directory
#' @keywords internal
db_context_registry_dir <- function() {
  # use cache scope for ephemeral session state
  dir <- tools::R_user_dir("brickster", which = "cache")
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  }
  dir
}

#' Context Registry Path
#' @keywords internal
db_context_registry_path <- function() {
  file.path(db_context_registry_dir(), "contexts.json")
}

#' Read Context Registry
#' @keywords internal
db_context_registry_read <- function() {
  path <- db_context_registry_path()
  if (!file.exists(path)) {
    return(list(contexts = list()))
  }
  out <- try(jsonlite::read_json(path, simplifyVector = FALSE), silent = TRUE)
  if (inherits(out, "try-error") || is.null(out$contexts)) {
    list(contexts = list())
  } else {
    out
  }
}

#' Write Context Registry
#' @keywords internal
db_context_registry_write <- function(registry) {
  path <- db_context_registry_path()
  jsonlite::write_json(registry, path, auto_unbox = TRUE, pretty = TRUE)
  invisible(path)
}

#' Generate a short, friendly alias from a context id
#' @keywords internal
db_context_alias_generate <- function(context_id) {
  # prefer first 8 chars of context id if looks like hex/uuid, else random
  if (is.character(context_id) && nchar(context_id) >= 8) {
    paste0("ctx-", substr(gsub("[^a-zA-Z0-9]", "", context_id), 1, 8))
  } else {
    paste0("ctx-", as.integer(runif(1, 100000, 999999)))
  }
}

#' Validate alias
#' @keywords internal
db_context_alias_valid <- function(alias) {
  is.character(alias) &&
    length(alias) == 1 &&
    grepl("^[a-z0-9][a-z0-9_-]{1,63}$", alias)
}

#' Register or update a context alias
#' @keywords internal
db_context_register <- function(alias, cluster_id, context_id, host, language) {
  if (is.null(alias) || !nzchar(alias)) {
    alias <- db_context_alias_generate(context_id)
  }
  alias <- tolower(alias)
  if (!db_context_alias_valid(alias)) {
    cli::cli_abort(
      "Invalid context alias: {.val {alias}}. Use lowercase letters, numbers, '-' or '_' (2-64 chars)."
    )
  }

  registry <- db_context_registry_read()

  # remove existing alias for this host (overwrite behavior)
  contexts <- registry$contexts
  # normalize empty
  if (is.null(contexts)) {
    contexts <- list()
  }

  # filter out entries with same alias + host (both should always be present)
  keep <- contexts |>
    purrr::keep(~ !(identical(.x$alias, alias) && identical(.x$host, host)))

  entry <- list(
    alias = alias,
    cluster_id = cluster_id,
    context_id = context_id,
    host = host,
    language = language,
    created_at = as.character(Sys.time())
  )

  registry$contexts <- c(keep, list(entry))
  db_context_registry_write(registry)
  invisible(alias)
}

#' Lookup a context by alias
#' @keywords internal
db_context_lookup <- function(alias, host = db_host()) {
  alias <- tolower(alias)
  registry <- db_context_registry_read()
  matches <- purrr::keep(
    registry$contexts,
    ~ identical(.x$alias, alias) && identical(.x$host, host)
  )
  if (length(matches) == 0) {
    return(NULL)
  }
  matches[[length(matches)]]
}

#' Remove a context alias
#' @keywords internal
db_context_unregister <- function(alias, host = db_host()) {
  alias <- tolower(alias)
  reg <- db_context_registry_read()
  reg$contexts <- reg$contexts |>
    purrr::keep(~ !(identical(.x$alias, alias) && identical(.x$host, host)))
  db_context_registry_write(reg)
  invisible(TRUE)
}

#' List contexts (data.frame)
#' @keywords internal
db_context_list <- function(host = NULL) {
  reg <- db_context_registry_read()
  xs <- reg$contexts
  if (length(xs) == 0) {
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
  # Bind rows safely even if entries have differing fields
  df <- dplyr::bind_rows(lapply(xs, function(x) {
    as.data.frame(x, stringsAsFactors = FALSE)
  }))
  if (!is.null(host)) {
    df <- df[df$host == host, , drop = FALSE]
  }
  rownames(df) <- NULL
  df
}

# nocov end
