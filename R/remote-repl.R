lang <- function(x = c("r", "py", "scala", "sql", "sh")) {
  x <- match.arg(x)
  switch(
    x,
    "r" = "R",
    "py" = emoji::emoji("snake"),
    scala = "scala",
    "sql" = "sql",
    "sh" = "sh"
  )
}

db_context_manager <- R6::R6Class(
  classname = "databricks_context_manager",
  private = list(
    cluster_id = NULL,
    context_id = NULL
  ),

  public = list(
    initialize = function(cluster_id, language = c("r", "py", "scala", "sql")) {
      language <- match.arg(language)
      cli::cli_alert_info("Attaching to {.strong {cluster_id}}...")
      private$cluster_id <- cluster_id
      brickster::get_and_start_cluster(private$cluster_id)
      ctx <- brickster::db_context_create(
        cluster_id = private$cluster_id,
        language   = language
      )
      private$context_id <- ctx$id
    },

    close = function() {
      brickster::db_context_destroy(
        context_id = private$context_id,
        cluster_id = private$cluster_id
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
        command = cmd
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
        command_id = command$id
      )
    },

    cmd_cancel = function(command) {
      brickster::db_context_command_cancel(
        command_id = command$id,
        context_id = private$context_id,
        cluster_id = private$cluster_id
      )
    }
  )
)


handle_cmd_error <- function(x, language) {
  summary <- x$results$summary
  cause <- x$results$cause

  if (language == "py") {
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
    pander::pandoc.table(tbl, style = "grid")
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
  if (language == "r") {
    out <- x$results$data
  } else if (language == "python") {
    out <- x$results$data
    is_html <- grepl(pattern = "<html|<div", out)
    if (is_html) {
      print(htmltools::HTML(out))
      out <- NULL
    }
  } else if (language == "scala") {
    out <- x$results$data
  } else {
    out <- x$results$data
  }
}


#' @param cluster_id Cluster Id to create REPL context against.
#'
#' @param language for REPL ('r', 'py', 'scala', 'sql', 'sh') are
#' supported.
#'
#' @export
db_repl <- function(cluster_id, language = c("r", "py", "scala", "sql", "sh")) {

  stopifnot(interactive())
  language <- match.arg(language)
  manager <- db_context_manager$new(
    cluster_id,
    if (language == "sh") "py" else language
  )
  on.exit(manager$close())
  prompt <- glue::glue("[{cluster_id}][{lang(language)}]>")
  while (TRUE) {
    cmd <- readline(prompt)
    if (cmd != "") {
      result <- manager$cmd_run(cmd, language)
      clean_result <- trimws(clean_cmd_results(result, language))
      if (length(clean_result) > 0 && clean_result != "") {
        cat(clean_result, "\n")
      }
    }
  }
}
