rstudio_editor_contents <- function(only_selected = FALSE) {
  if (rstudioapi::isAvailable()) {
    context <- rstudioapi::getSourceEditorContext()
    if (only_selected) {
      text <- context$selection[[1]]$text
    } else {
      text <- context$contents
    }
  }
}

prepare_code_for_repl <- function(text) {
  exprs <- gsub("\\\n", "", as.character(parse(text = text)))
  paste(exprs, collapse = "\n")
}

send_selection <- function() {
  code <- rstudio_editor_contents(only_selected = TRUE)
  code <- prepare_code_for_repl(code)
  rstudioapi::sendToConsole(code = code, execute = TRUE)
}

send_document <- function() {
  code <- rstudio_editor_contents(only_selected = FALSE)
  code <- prepare_code_for_repl(code)
  rstudioapi::sendToConsole(code = code, execute = TRUE)
}

send_file <- function() {
  script <- rstudioapi::selectFile(filter = "*.R", existing = TRUE)
  if (!is.null(script) || script != "") {
    code <- prepare_code_for_repl(readLines(script))
    rstudioapi::sendToConsole(code = code, execute = TRUE)
  }
}
