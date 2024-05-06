#' Detect if running within Databricks Notebook
#'
#' @details
#' R sessions on Databricks can be detected via various environment variables
#' and directories.
#'
#' @return Boolean
#' @export
in_databricks_nb <- function() {
  ("/databricks/spark/R/lib"  %in% .libPaths()) &&
    exists("DATABRICKS_GUID", envir = .GlobalEnv)
}

#' Setup Databricks Notebook with Posit Package Manager
#'
#' @details
#' Databricks notebooks default repo for package installation is CRAN.
#' CRAN doesn't provide pre-compiled binaries for linux and this results in
#' packages taking longer than desired.
#'
#' This function can be called within a Databricks notebook to easily switch to
#' Posit and retrieve pre-compiled binaries.
#'
#' This function will behave correctly across different Databricks Runtimes,
#' even when the underlying linux version changes.
#'
#' @export
notebook_use_posit_repo <- function() {
  if (in_databricks_nb()) {
    agent <- sprintf("R/%s R (%s)", getRversion(), paste(getRversion(), R.version["platform"], R.version["arch"], R.version["os"]))
    codename <- system("lsb_release -c --short", intern = T)
    mirror <- paste0("https://packagemanager.posit.co/cran/__linux__/", codename, "/latest")
    options(
      HTTPUserAgent = agent,
      repos = c(POSIT = mirror, getOption("repos"))
    )
  }
}

#' Enable htmlwidgets in Databricks Notebook
#'
#' @details
#' Databricks notebooks by default don't currently support htmlwidgets.
#' This behaviour can be corrected by:
#'  - adjusting the print method in htmltools
#'  - installing pandoc
#'
#' This is a invasive method to correct the behaviour as htmltools isn't
#' flexible to adjust via the `viewer` option directly.
#'
#' It only runs within a Databricks notebook cell.
#'
#' The height can be adjusted without running the function again by using the
#' `db_htmlwidget_height` option (e.g. `options(db_htmlwidget_height = 300)`).
#'
#'
#' @param height Measurement passed to height of htmlwidget. This overrides
#' existing values that may often be `NULL` to ensure the height is correctly
#' displayed within the iframe of notebook results cells (via `displayHTML()`).
#' Default is 450.
#'
#' @export
#'
#' @examples
#' notebook_enable_htmlwidgets()
#' # set default height to 800px
#' notebook_enable_htmlwidgets(height = 800)
notebook_enable_htmlwidgets <- function(height = 450) {
  if (in_databricks_nb()) {

    # new option to control default widget height, default is 450px
    options(db_htmlwidget_height = height)

    system("apt-get --yes install pandoc", intern = T)
    if (!base::require("htmlwidgets")) {
      utils::install.packages("htmlwidgets")
    }

    # new method will fetch height based on new option, or default to 450px
    new_method <- function(x, ...) {
      x$height <- getOption("db_htmlwidget_height", 450)
      file <- tempfile(fileext = ".html")
      htmlwidgets::saveWidget(x, file = file)
      contents <- as.character(rvest::read_html(file))
      displayHTML(contents)
    }

    utils::assignInNamespace("print.htmlwidget", new_method, ns = "htmlwidgets")
    invisible(list(default_height = height, print = new_method))
  }
}
