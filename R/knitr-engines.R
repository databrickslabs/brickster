#' Databricks knitr Engine Template
#'
#' @param options knitr chunk options.
#' @inheritParams db_context_command_run
#' @noRd
db_engine_template <- function(options, language) {

  # authentication is fetched from .Renviron
  cmd <- db_context_command_run(
    cluster_id = options$db_cluster_id,
    context_id = options$db_exec_context,
    language = language,
    command = paste(options$code, collapse = "\n")
  )

  # keep checking command status
  cmd_status <- ke_check_command_status(cmd, options)

  while (cmd_status$status %in% c("Running", "Queued")) {
    Sys.sleep(2)
    cmd_status <- ke_check_command_status(cmd, options)
  }

  clean_command_results(cmd_status, options, language = language)
}

#' Databricks knitr Engine (R)
#'
#' @inheritParams db_engine_template
#' @noRd
db_engine_r <- function(options) {
  db_engine_template(options, language = "r")
}


#' Databricks knitr Engine (Python)
#'
#' @inheritParams db_engine_templat
#' @noRd
db_engine_py <- function(options) {
  db_engine_template(options, language = "python")
}

#' Databricks knitr Engine (Scala)
#'
#' @inheritParams db_engine_template
#' @noRd
db_engine_scala <- function(options) {
  db_engine_template(options, language = "scala")
}


#' Databricks knitr Engine (SQL)
#'
#' @inheritParams db_engine_template
#' @noRd
db_engine_sql <- function(options) {
  db_engine_template(options, language = "sql")
}

#' Clean Command Output From Execution Context
#'
#' @param x Output from [ke_check_command_status()].
#' @inheritParams db_engine_template
#' @inheritParams db_context_command_run
#' @noRd
clean_command_results <- function(x, options, language) {

  options$comment <- ""

  if (x$results$resultType == "error") {
    msg <- paste(x$results$summary, x$results$cause, sep = "\n")
    stop(msg, call. = FALSE)
  }

  # create data.table and return as {kable} table
  if (x$results$resultType == "table") {

    outputs <- list(sep = "\n\n")
    if (options$echo) {
      outputs$code <- knitr::engine_output(
        options = options,
        code = options$code,
        out = NULL
      )
    }

    if (options$eval) {
      schema <- data.table::rbindlist(x$results$schema)
      tbl <- data.table::rbindlist(x$results$data)
      names(tbl) <- schema$name
      if (!is.null(options$keep_as)) {
        base::assign(options$keep_as, value = tbl, envir = .GlobalEnv)
      }
      if (isTRUE(getOption('knitr.in.progress'))) {
        outputs$table <- knitr::engine_output(
          options = options,
          out = list(paste0(knitr::kable(tbl), collapse = "\n"))
        )
      } else {
        knitr::knit_print(tbl)
      }

    }

    return(do.call(paste, outputs))

  }

  # when result is an image save and present
  if (x$results$resultType %in% c("images", "image")) {

    outputs <- list(sep = "\n\n")
    if (options$echo) {
      outputs$code <- knitr::engine_output(
        options = options,
        code = options$code,
        out = NULL
      )
    }

    if (options$eval) {
      img <- x$results$fileNames[[1]]
      # read as raw
      raw <- base64enc::base64decode(what = substr(img, 23, nchar(img)))
      img <- magick::image_read(raw)
      # save to temp location
      file <- tempfile(fileext = ".png")
      magick::image_write(img, path = file)
      # knitr things...
      if (isTRUE(getOption('knitr.in.progress'))) {
        outputs$plot <- knitr::engine_output(
          options = options,
          out = list(knitr::include_graphics(path = file))
        )
      } else {
        res <- structure(file, class = c("knit_image_paths", "knit_asis"), dpi = options$dpi)
        print(res)
      }
    }

    return(do.call(paste, outputs))

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

  knitr::engine_output(options = options, code = options$code, out = out)

}


#' Check Command Status Helper
#'
#' @param cmd Command to run against an execution context
#' @inheritParams db_context_command_run
#' @noRd
ke_check_command_status <- function(cmd, options) {
  db_context_command_status(
    cluster_id = options$db_cluster_id,
    context_id = options$db_exec_context,
    command_id = cmd$id
  )
}
