lang <- function(x = c("r", "py", "scala", "sql", "sh")) {
  x <- match.arg(x)
  switch(
    x,
    "r" = "R",
    "py" = "py",
    "scala" = "scala",
    "sql" = "sql",
    "sh" = "sh"
  )
}

# nocov start
db_context_manager <- R6::R6Class(
  classname = "databricks_context_manager",
  private = list(
    cluster_id = NULL,
    context_id = NULL,
    host = NULL,
    token = NULL
  ),

  public = list(
    initialize = function(cluster_id, language = c("r", "py", "scala", "sql"),
                          host = db_host(), token = db_token()) {
      language <- match.arg(language)
      private$cluster_id <- cluster_id
      private$host <- host
      private$token <- token
      cluster_info <- get_and_start_cluster(
        private$cluster_id,
        host = host,
        token = token
      )
      cli::cli_progress_step(
        msg = "{.header Creating execution context...}",
        msg_done = "{.header Execution context created}"
      )
      ctx <- brickster::db_context_create(
        cluster_id = private$cluster_id,
        language   = language,
        host = host,
        token = token
      )
      private$context_id <- ctx$id
      cli::cli_progress_done()
      cli::cli_end()
    },

    close = function() {
      brickster::db_context_destroy(
        context_id = private$context_id,
        cluster_id = private$cluster_id,
        host = private$host,
        token = private$token
      )
    },

    cmd_run =  function(cmd, language = c("r", "py", "scala", "sql", "sh")) {
      language <- match.arg(language)
      code = paste(cmd, collapse = "\n")

      if (language == "sh") {
        cmd <- paste0("%%sh\n", cmd)
        language <- "py"
      }

      cmd <- brickster::db_context_command_run(
        cluster_id = private$cluster_id,
        context_id = private$context_id,
        language = language,
        command = cmd,
        host = private$host,
        token = private$token
      )

      cmd_status <- self$cmd_status(cmd)
      while (cmd_status$status %in% c("Running", "Queued")) {
        Sys.sleep(0.5)
        cmd_status <- self$cmd_status(cmd)
      }

      cmd_status

    },

    cmd_status = function(command) {
      brickster::db_context_command_status(
        cluster_id = private$cluster_id,
        context_id = private$context_id,
        command_id = command$id,
        host = private$host,
        token = private$token
      )
    },

    cmd_cancel = function(command) {
      brickster::db_context_command_cancel(
        command_id = command$id,
        context_id = private$context_id,
        cluster_id = private$cluster_id,
        host = private$host,
        token = private$token
      )
    }
  )
)
# nocov end


handle_cmd_error <- function(x, language) {
  summary <- x$results$summary
  cause <- x$results$cause

  if (language %in% c("py", "sh")) {
    msg <- cause
  }

  if (language == "r") {
    if (grepl("DATABRICKS_CURRENT_TEMP_CMD__", cause)) {
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

clean_cmd_results <- function(x, language) {

  if (x$results$resultType == "error") {
    cli_alert_danger(handle_cmd_error(x, language))
    return(NULL)
  }

  if (x$results$resultType == "table") {
    schema <- data.table::rbindlist(x$results$schema)
    tbl <- data.table::rbindlist(x$results$data)
    names(tbl) <- schema$name

    output_tbl <- huxtable::hux(tbl) %>%
      huxtable::set_all_borders(TRUE) %>%
      huxtable::set_font_size(10) %>%
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

repl_prompt <- function(language) {
  glue::glue("[Databricks][{lang(language)}]> ")
}

# nocov start
#' Remote REPL to Databricks Cluster
#'
#' @details This function doesn't accept `token` and `host` parameters,
#' credentials must be established as per documentation best practice
#' (e.g. `.Renviron`).
#'
#' `db_repl()` will take over the existing console and allow execution of
#' commands against a Databricks cluster. For RStudio users there are Addins
#' which can be bound to keyboard shortcuts to improve usability.
#'
#' @param cluster_id Cluster Id to create REPL context against.
#' @param language for REPL ('r', 'py', 'scala', 'sql', 'sh') are
#' supported.
#' @inheritParams auth_params
#'
#' @export
db_repl <- function(cluster_id, language = c("r", "py", "scala", "sql", "sh"),
                    host = db_host(), token = db_token()) {

  if(!interactive()) {
    cli::cli_abort("{.fn db_repl} can only be called in an interactive context")
  }

  language <- match.arg(language)
  manager <- db_context_manager$new(
    cluster_id,
    if (language == "sh") "py" else language,
    host = host,
    token = token
  )
  on.exit(manager$close())
  prompt <- repl_prompt(language)

  while (TRUE) {
    cmd <- readline(prompt)
    # change language when command is `:{language}` (e.g. :py)
    if (cmd %in% c(":r", ":py", ":scala", ":sql", ":sh")) {
      new_lang <- substr(cmd, 2, 99)
      language <- new_lang
      prompt <- repl_prompt(language)
    } else if (cmd != "") {
      result <- manager$cmd_run(cmd, language)
      clean_result <- trimws(clean_cmd_results(result, language))
      if (length(clean_result) > 0 && clean_result != "") {
        cat(clean_result, "\n")
      }
    }
  }
}
# nocov end
