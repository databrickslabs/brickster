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

#' Databricks Execution Context Manager (R6 Class)
#'
#' `db_context_manager()` provides a simple interface to send commands to
#' Databricks cluster and return the results.
#'
#' @importFrom R6 R6Class
#' @export
db_context_manager <- R6::R6Class(
  classname = "databricks_context_manager",
  private = list(
    cluster_id = NULL,
    context_id = NULL,
    host = NULL,
    token = NULL
  ),

  public = list(
    #' @description Create a new context manager object.
    #' @param cluster_id The ID of the cluster to execute command on.
    #' @param language One of `r`, `py`, `scala`, `sql`, or `sh`.
    #' @param host Databricks workspace URL, defaults to calling [db_host()].
    #' @param token Databricks workspace token, defaults to calling [db_token()].
    #' @return A new `databricks_context_manager` object.
    initialize = function(
      cluster_id,
      language = c("r", "py", "scala", "sql", "sh"),
      host = db_host(),
      token = db_token()
    ) {
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
      ctx <- db_context_create(
        cluster_id = private$cluster_id,
        language = language,
        host = host,
        token = token
      )
      private$context_id <- ctx$id
      cli::cli_progress_done()
      cli::cli_end()
    },

    #' @description Destroy the execution context
    close = function() {
      db_context_destroy(
        context_id = private$context_id,
        cluster_id = private$cluster_id,
        host = private$host,
        token = private$token
      )
    },

    #' @description Execute a command against a Databricks cluster
    #' @param cmd code to execute against Databricks cluster
    #' @param language One of `r`, `py`, `scala`, `sql`, or `sh`.
    #' @return Command results
    cmd_run = function(cmd, language = c("r", "py", "scala", "sql", "sh")) {
      language <- match.arg(language)
      code <- paste(cmd, collapse = "\n")

      if (language == "sh") {
        cmd <- paste0("%%sh\n", cmd)
        language <- "py"
      }

      cmd <- db_context_command_run_and_wait(
        cluster_id = private$cluster_id,
        context_id = private$context_id,
        language = language,
        command = cmd,
        host = private$host,
        token = private$token,
        parse_result = TRUE
      )

      cmd
    }
  )
)
# nocov end

repl_prompt <- function(language) {
  glue::glue("[Databricks][{lang(language)}]> ")
}

# nocov start
#' Remote REPL to Databricks Cluster
#'
#' @details
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
db_repl <- function(
  cluster_id,
  language = c("r", "py", "scala", "sql", "sh"),
  host = db_host(),
  token = db_token()
) {
  if (!interactive()) {
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

  # prompts for current language
  prompt_main <- repl_prompt(language)
  prompt_cont <- sub("([> ]+)$", "+ ", prompt_main)
  buffer <- character()

  repeat {
    # choose prompt based on R-buffer state
    prompt <- if (language == "r" && length(buffer) > 0) {
      prompt_cont
    } else {
      prompt_main
    }
    line <- readline(prompt)

    # language-switch command always applies at top-level (empty R buffer)
    if (
      length(buffer) == 0 && line %in% c(":r", ":py", ":scala", ":sql", ":sh")
    ) {
      language <- sub("^:", "", line)
      prompt_main <- repl_prompt(language)
      prompt_cont <- sub("([> ]+)$", "+ ", prompt_main)
      buffer <- character() # drop any partial R buffer
      next
    }

    if (language == "r") {
      # buffer every R line
      buffer <- c(buffer, line)
      parsed <- try(parse(text = paste(buffer, collapse = "\n")), silent = TRUE)

      if (inherits(parsed, "try-error")) {
        # incomplete R block? keep reading
        if (grepl("unexpected end of input", parsed[1], fixed = TRUE)) {
          next
        }
        # real syntax error: show it, reset buffer
        cat("Syntax error:", parsed[1], "\n")
        buffer <- character()
        next
      }

      # complete R expression(s) - send them as one chunk
      code <- paste(buffer, collapse = "\n")
      res <- manager$cmd_run(code, "r")
      out <- trimws(res)
      if (length(out) > 0 && nzchar(out)) {
        cat(out, "\n")
      }
      buffer <- character()
    } else {
      # non-R: single-line send
      if (nzchar(line)) {
        res <- manager$cmd_run(line, language)
        out <- trimws(res)
        if (length(out) > 0 && nzchar(out)) cat(out, "\n")
      }
    }
  }
}
# nocov end
