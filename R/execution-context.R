#' Create an Execution Context
#'
#' @param cluster_id The ID of the cluster to create the context for.
#' @param language The language for the context. One of `python`, `sql`, `scala`,
#' `r`.
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @family Execution Context API
#'
#' @export
db_context_create <- function(
  cluster_id,
  language = c("python", "sql", "scala", "r"),
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  language <- match.arg(language, several.ok = FALSE)

  body <- list(
    clusterId = cluster_id,
    language = language
  )

  req <- db_request(
    endpoint = "contexts/create",
    method = "POST",
    version = "1.2",
    body = body,
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }
}

#' Delete an Execution Context
#'
#' @param context_id The ID of the execution context.
#' @inheritParams auth_params
#' @inheritParams db_context_create
#' @inheritParams db_sql_warehouse_create
#'
#' @family Execution Context API
#'
#' @export
db_context_destroy <- function(
  cluster_id,
  context_id,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  body <- list(
    clusterId = cluster_id,
    contextId = context_id
  )

  req <- db_request(
    endpoint = "contexts/destroy",
    method = "POST",
    version = "1.2",
    body = body,
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }
}

#' Get Information About an Execution Context
#'
#' @inheritParams auth_params
#' @inheritParams db_context_destroy
#' @inheritParams db_sql_warehouse_create
#'
#' @family Execution Context API
#'
#' @export
db_context_status <- function(
  cluster_id,
  context_id,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  req <- db_request(
    endpoint = "contexts/status",
    method = "GET",
    version = "1.2",
    host = host,
    token = token
  )

  req <- req |>
    httr2::req_url_query(
      clusterId = cluster_id,
      contextId = context_id
    )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }
}

#' Run a Command
#'
#' @param command The command string to run.
#' @param command_file The path to a file containing the command to run.
#' @param options Named list of values used downstream. For example, a
#' 'displayRowLimit' override (used in testing).
#' @inheritParams auth_params
#' @inheritParams db_context_destroy
#' @inheritParams db_context_create
#' @inheritParams db_sql_warehouse_create
#'
#' @family Execution Context API
#'
#' @export
db_context_command_run <- function(
  cluster_id,
  context_id,
  language = c("python", "sql", "scala", "r"),
  command = NULL,
  command_file = NULL,
  options = list(),
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  language <- match.arg(language, several.ok = FALSE)

  # only can have one of `command` or `command_file`
  if (!is.null(command) && !is.null(command_file)) {
    cli::cli_abort(
      "Must specify {.arg command} OR {.arg command_file}, not both."
    )
  }

  if (!is.null(command_file)) {
    command <- curl::form_file(command_file)
  }

  req <- db_request(
    endpoint = "commands/execute",
    method = "POST",
    version = "1.2",
    body = NULL,
    host = host,
    token = token
  )

  req <- httr2::req_body_multipart(
    req,
    clusterId = cluster_id,
    contextId = context_id,
    language = language,
    command = command,
    options = options
  )

  if (perform_request) {
    res <- db_perform_request(req)
    list(id = res$id, language = language)
  } else {
    req
  }
}

#' Run a Command and Wait For Results
#'
#' @param parse_result Boolean, determines if results are parsed automatically.
#' @inheritParams db_context_command_run
#'
#' @family Execution Context API
#'
#' @export
db_context_command_run_and_wait <- function(
  cluster_id,
  context_id,
  language = c("python", "sql", "scala", "r"),
  command = NULL,
  command_file = NULL,
  options = list(),
  parse_result = TRUE,
  host = db_host(),
  token = db_token()
) {
  stopifnot(is.logical(parse_result))

  command <- db_context_command_run(
    cluster_id = cluster_id,
    context_id = context_id,
    language = language,
    command = command,
    command_file = command_file,
    options = options,
    host = host,
    token = token
  )

  command_status <- db_context_command_status(
    cluster_id = cluster_id,
    context_id = context_id,
    command_id = command$id,
    host = host,
    token = token
  )

  while (command_status$status %in% c("Running", "Queued")) {
    Sys.sleep(0.5)
    command_status <- db_context_command_status(
      cluster_id = cluster_id,
      context_id = context_id,
      command_id = command$id,
      host = host,
      token = token
    )
  }

  if (parse_result) {
    db_context_command_parse(command_status, language = language)
  } else {
    command_status
  }
}

#' Get Information About a Command
#'
#' @param command_id The ID of the command to get information about.
#' @inheritParams auth_params
#' @inheritParams db_context_status
#' @inheritParams db_sql_warehouse_create
#'
#' @family Execution Context API
#'
#' @export
db_context_command_status <- function(
  cluster_id,
  context_id,
  command_id,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  req <- db_request(
    endpoint = "commands/status",
    method = "GET",
    version = "1.2",
    host = host,
    token = token
  )

  req <- req |>
    httr2::req_url_query(
      clusterId = cluster_id,
      contextId = context_id,
      commandId = command_id
    )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }
}

#' Cancel a Command
#'
#' @inheritParams auth_params
#' @inheritParams db_context_command_status
#' @inheritParams db_sql_warehouse_create
#'
#' @family Execution Context API
#'
#' @export
db_context_command_cancel <- function(
  cluster_id,
  context_id,
  command_id,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  body <- list(
    clusterId = cluster_id,
    contextId = context_id,
    commandId = command_id
  )

  req <- db_request(
    endpoint = "commands/cancel",
    method = "POST",
    version = "1.2",
    body = body,
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }
}

#' Parse Command Results
#'
#' @param x command output from `db_context_command_status` or
#' `db_context_manager`'s `cmd_run`
#' @param language
#'
#' @family Execution Context API
#'
#' @return command results
#' @keywords internal
db_context_command_parse <- function(
  x,
  language = c("r", "py", "scala", "sql")
) {
  language <- match.arg(language)

  # Check for required suggested packages
  required_pkgs <- c("huxtable", "magick", "grid", "htmltools")
  missing_pkgs <- required_pkgs[
    !purrr::map_lgl(required_pkgs, rlang::is_installed)
  ]

  if (length(missing_pkgs) > 0) {
    cli::cli_abort(
      "Required packages missing: {.pkg {missing_pkgs}}. Install with: install.packages({deparse(missing_pkgs)})"
    )
  }

  if (x$results$resultType == "error") {
    cli::cli_alert_danger(handle_cmd_error(x, language))
    return(NULL)
  }

  if (x$results$resultType == "table") {
    schema <- dplyr::bind_rows(x$results$schema)

    tbl <- purrr::list_transpose(x$results$data) |>
      as.data.frame()

    names(tbl) <- schema$names

    output_tbl <- huxtable::hux(tbl) |>
      huxtable::set_all_borders() |>
      huxtable::set_font_size(10) |>
      huxtable::set_position("left")
    huxtable::print_screen(output_tbl)
    return(NULL)
  }

  # when result is an image save and present
  if (x$results$resultType %in% c("images", "image")) {
    img <- x$results$fileNames[[1]]
    # read as raw
    raw <- base64enc::base64decode(what = substr(img, 23, nchar(img)))
    img <- magick::image_read(raw)
    grid::grid.newpage()
    return(grid::grid.raster(img))
  }

  # otherwise treat the results as standard output
  # each language needs its own special treatment
  out <- x$results$data

  # if that output is HTML render via htmltools
  if (grepl(pattern = "<html|<div", out)) {
    htmltools::html_print(htmltools::HTML(out))
    out <- NULL
  }

  out
}

handle_cmd_error <- function(x, language) {
  summary <- x$results$summary
  cause <- x$results$cause

  if (language %in% c("py", "sh")) {
    msg <- cause
  }

  if (language == "r") {
    if (grepl("DATABRICKS_CURRENT_TEMP_CMD__", cause, fixed = TRUE)) {
      msg <- substring(cause, 62)
    } else {
      msg <- cause
    }
  }

  if (language %in% c("sql", "scala")) {
    msg <- summary
  }

  trimws(msg)
}
