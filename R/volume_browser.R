# A volume browser as a shiny app
#
# UI choices
# ==========
#
# The app tries to be similar to the files browser in RStudio, so users
# already used to the file browser can adapt to it.
#
# Credential management
# =======================
#
# The easiest way to handle the token would be to pass it to the shiny app when
# we start it, so the shiny backend has it.
#
# This is a bad idea because if the shiny app is exposed on e.g. port http://localhost:3000,
# anyone in your computer could browse that URL and access your volumes. Even
# if the port is selected randomly, testing 5000 ports is easy.
#
# The approach taken here is:
#
# - When the shiny app is started, a secret key is generated. We give the shiny
#   server backend that key.
# - When browse_path() is used to browse a path, using a host and token,
#   the host and token are encrypted with the key.
# - The encrypted credentials are passed in a URL parameter.
# - The web browser (Viewer panel), receives the credentials in the URL
#   and passes them to the shiny server, that has the key to decrypt them.
# - The shiny server decrypts the credentials and uses them to make the requests.
#
# This design provides the following advantages:
# - The web browser does not know the databricks access token. No way to steal it
#   without access to the shiny backend process.
# - The access token is available in the backend in the scope of the http session.
# - The host and access token depend on the browser session, so it is possible
#   to use the same shiny app with several credentials (e.g. switch to a different
#   unity catalog connection without restarting the shiny app).
#
# Besides, with this approach, an evil local user would need to spoof your shiny
# session. This is reasonably harder than just "let's try these 5000 urls".

fullpath_to_pathcomponents <- function(full_path) {
  # This function takes a path like:
  # /Volume/catalog/schema/volume/path/to/somewhere
  # and returns the catalog, schema, volume and path components, or NULL if the
  # given full_path is invalid
  out <- list(catalog=NULL, schema=NULL, volume=NULL, path=NULL)
  if (full_path == "/Volumes") {
    return(out)
  }
  if (!startsWith(full_path, "/Volumes/")) {
    # Error:
    return(NULL)
  }
  # pattern="/+" ensures /Volumes//catalog/schema/ is interpreted as /Volumes/catalog/schema/
  components <- stringr::str_split(full_path, pattern = "/+", n=6)[[1]]
  # components[1] == "/"
  # components[2] == "Volumes"
  # components[3] is the catalog name
  # components[4] is the schema name
  # components[5] is the volume name
  # components[6] is the rest of the path
  #
  # We just need to consider that with a trailing slash, the last element
  # may exist but be an empty string, which would mean it is not set.
  if (length(components) == 3) {
    if (components[3] == "") {
      return(out)
    }
    out$catalog <- components[3]
    return(out)
  }
  if (length(components) == 4) {
    out$catalog <- components[3]
    if (components[4] == "") {
      return(out)
    }
    out$schema <- components[4]
    return(out)
  }
  if (length(components) == 5) {
    out$catalog <- components[3]
    out$schema <- components[4]
    if (components[5] == "") {
      return(out)
    }
    out$volume <- components[5]
    return(out)
  }
  if (length(components) == 6) {
    out$catalog <- components[3]
    out$schema <- components[4]
    out$volume <- components[5]
    if (components[6] == "") {
      return(out)
    }
    out$path <- components[6]
    return(out)
  }
  stop("Assertion Error: Code should never reach this point")
}


create_databricks_url_for_path <- function(full_path, host, ws_id) {
  # This helper function returns a link to your databricks instance to browse
  # the given path.
  x <- fullpath_to_pathcomponents(full_path)
  full_path_urlenc <- NULL
  if (is.null(x$catalog)) {
    path1 <- ""
  } else if (is.null(x$schema)) {
    path1 <- x$catalog
  } else if (is.null(x$volume)) {
    path1 <- paste(x$catalog, x$schema, sep="/")
  } else {
    path1 <- paste("volumes", x$catalog, x$schema, x$volume, sep="/")
    full_path_urlenc <- utils::URLencode(full_path, reserved=TRUE)
  }
  if (is.null(full_path_urlenc)) {
    url <- glue::glue("https://{host}/explore/data/{path1}?o={ws_id}")
  } else {
    url <- glue::glue("https://{host}/explore/data/{path1}?o={ws_id}&volumePath={full_path_urlenc}")
  }
  url
}


create_folder_link <- function(text, fullpath, escape = TRUE) {
  # Returns html code equivalent to:
  # <a onclick="js-code-to-create-a-shiny-event">text</a>
  # The js code triggers a input$clicked_folder event reporting the clicked path
  # encoded in base64.
  if (escape) {
    text <- htmltools::htmlEscape(text)
  }
  # Reverse operation from the clicked_folder observe event:
  fullpath_b64 <- openssl::base64_encode(charToRaw(fullpath))
  paste0(
    "<a href='#' onclick=\"Shiny.setInputValue('clicked_folder', '", fullpath_b64, "', {priority: 'event'})\">",
    text,
    "</a>"
  )
}

select_file_link <- function(text, fullpath, escape = TRUE) {
  # Returns html code equivalent to:
  # <a onclick="js-code-to-create-a-shiny-event">text</a>
  # The js code triggers a input$clicked_file event reporting the clicked path
  # encoded in base64.
  if (escape) {
    text <- htmltools::htmlEscape(text)
  }
  fullpath_b64 <- openssl::base64_encode(charToRaw(fullpath))
  paste0(
    "<a href='#' onclick=\"Shiny.setInputValue('clicked_file', '", fullpath_b64, "', {priority: 'event'})\">",
    text,
    "</a>"
  )
}

get_cache_key <- function(full_path, host, token) {
  # We use the cache to avoid requesting to the catalog the same folder more than once.
  # The cache requires that keys only include lower case letters, digits and
  # the underscore "_" and hyphen "-" characters.
  #
  # Since the token is part of the key, and the key might be used as a file name
  # if a cache_disk() was used, I will use a cryptographically safe hash
  openssl::sha256(paste0(full_path, host, token, collapse="\n"))
}

get_files_table <- function(full_path, cache, host = db_host(), token = db_token()) {
  # Return a data frame with the file list found in the path.
  # The cache is used to avoid repeating the same requests to the unity catalog
  # FIXME: Pagination. Only the first 1000 elements are shown.
  cache_key <- get_cache_key(full_path, host, token)

  # Fetch the table from the cache if available:
  out <- cache$get(cache_key, NULL)
  if (!is.null(out)) {
    return(out)
  }
  # Get the catalog, schema, volume and path from the full path
  x <- fullpath_to_pathcomponents(full_path)
  if (is.null(x)) {
    return(NULL)
  }
  catalog <- x$catalog
  schema <- x$schema
  volume <- x$volume
  path <- x$path
  if (is.null(catalog)) {
    # FIXME: Pagination
    x <- db_uc_catalogs_list(host = host, token = token)
    catalog_names <- purrr::map_chr(x, "name")
    df <- data.frame(
      Name = catalog_names,
      Size = rep(NA_real_, length(x)),
      Modified = as.POSIXct(purrr::map_dbl(x, "updated_at")/1000, tz = "UTC"),
      FullPath = stringr::str_c("/Volumes/", catalog_names, "/"),
      ObjectType = rep("CATALOG", length(x))
    )
    cache$set(cache_key, df)
    return(df)
  }
  if (is.null(schema)) {
    # FIXME: Pagination
    x <- db_uc_schemas_list(catalog=catalog, host=host, token=token)
    schema_names <- purrr::map_chr(x, "name")
    df <- data.frame(
      Name = c("..", schema_names),
      Size = NA_real_,
      Modified = as.POSIXct(c(NA_real_, purrr::map_dbl(x, "updated_at"))/1000, tz = "UTC"),
      FullPath = c(
        paste0(dirname(full_path), "/"),
        stringr::str_c("/Volumes/", catalog, "/", schema_names, "/")
      ),
      ObjectType = c("UP", rep("SCHEMA", length(x)))
    )
    cache$set(cache_key, df)
    return(df)
  }
  if (is.null(volume)) {
    # FIXME: Pagination
    x <- db_uc_volumes_list(catalog=catalog, schema=schema, host=host, token=token)
    volume_names <- purrr::map_chr(x, "name")
    df <- data.frame(
      Name = c("..", volume_names),
      Size = rep(NA_real_, 1 + length(x)),
      Modified = as.POSIXct(c(NA_real_, purrr::map_dbl(x, "updated_at"))/1000, tz = "UTC"),
      FullPath = c(
        paste0(dirname(full_path), "/"),
        stringr::str_c("/Volumes/", catalog, "/", schema, "/", volume_names, "/")
      ),
      ObjectType = c("UP", rep("VOLUME", length(x)))
    )
    cache$set(cache_key, df)
    return(df)
  }

  x <- db_volume_list(full_path, host=host, token=token)$contents
  df <- data.frame(
    Name = c("..", purrr::map_chr(x, "name")),
    Size = c(NA_real_, purrr::map_dbl(x,~.$file_size %||% NA_real_)),
    Modified = as.POSIXct(
      c(NA_real_,purrr::map_dbl(x, ~ (.$last_modified %||% NA_real_) / 1000)),
      tz = "UTC"
    ),
    FullPath = c(paste0(dirname(full_path), "/"), purrr::map_chr(x, "path")),
    ObjectType = c("UP", ifelse(purrr::map_lgl(x, "is_directory"), "DIRECTORY", "FILE"))
  )
  cache$set(cache_key, df)
  return(df)
}

encrypt_credentials <- function(host, token, key) {
  payload <- openssl::aes_ctr_encrypt(
    charToRaw(
      glue::glue("{host}\n{token}")
    ),
    key = key
  )
  iv <- attr(payload, "iv")
  if (length(iv) != 16) {
    stop("Assertion error: Defaults in openssl may have changed. Please adapt encrypt_credentials")
  }
  cred <- openssl::base64_encode(
    c(iv, payload)
  )
  utils::URLencode(cred, reserved = TRUE)
}

decrypt_credentials <- function(credentials, key) {
  credentials <- utils::URLdecode(credentials)
  iv_payload <- openssl::base64_decode(credentials)
  if (length(iv_payload) <= 16) {
    return(NULL)
  }
  iv <- iv_payload[1:16]
  payload <- iv_payload[17:length(iv_payload)]
  host_token <- rawToChar(
    openssl::aes_ctr_decrypt(
      payload,
      key = key,
      iv = iv
    )
  )
  host_token <- strsplit(host_token, split = "\n", fixed = TRUE)[[1]]
  if (length(host_token) != 2) {
    return(NULL)
  }
  list(host=host_token[1], token=host_token[2])
}


volume_browser_app <- function(init_path = "/Volumes/", key) {
  force(init_path)
  force(key)

  ui <- shiny::fluidPage(
    title = "Unity Catalog Volume Browser",
    htmltools::tags$head(
      shinyjs::useShinyjs(),
      htmltools::tags$style(
      htmltools::HTML("
      body {
        background-color: #f9f9f9;
      }

      .file-browser {
        font-family: 'Segoe UI', sans-serif;
        margin-top: 0.1em;
        margin-left: 0.1em;
        padding-left: 0.1em;
        margin-bottom: 1em;
        background-color: #f9f9f9;
      }
      .bar {
        background-color: #f9f9f9;
        display: flex;
        align-items: center;
        flex-wrap: nowrap;
        gap: 3px;
        padding-top:10px;
        padding-bottom:10px;
        .action-button {
          padding: 0.2em;
        }
      }
      @media (max-width: 40ch) {
        .bar {
          .action-button {
            .button-text {
              display: none;
            }
          }
        }
      }

      #selected_file {
       font-family: \"Lucida Console\", \"Courier New\", monospace;
       font-size: 10pt;
       color: #333;
       background-color: #f5f5f5;
       border: 1px solid #ccc;
       border-radius: 4px;
      }
    "))
    ),

    htmltools::div(
      class = "file-browser",
      htmltools::div(
        class = "bar",
        # It would be great if the labels would shorten or disappear depending on the width
        shiny::actionButton(
          "new_folder_modal",
          htmltools::span("New Folder", class="button-text"),
          icon=shiny::icon("folder"),
          title = "New folder"
          ),
        shiny::actionButton(
          "upload_file",
          htmltools::span("Upload file", class="button-text"),
          icon=shiny::icon("file-arrow-up"),
          title = "Upload file"
        ),
        shiny::actionButton(
          "delete",
          htmltools::span("Delete file", class="button-text"),
          icon=shiny::icon("xmark"),
          title = "Delete file"
        ),
        shiny::actionButton(
          "open_in_databricks",
          htmltools::span("Open in Databricks", class="button-text"),
          icon=shiny::icon("arrow-up-right-from-square"),
          title = "Open in Databricks"
        ),
        shiny::actionButton(
          "go_to_path",
          htmltools::span("Go to", class="button-text"),
          icon=shiny::icon("compass"),
          title = "Go to folder"
        ),
        shiny::actionButton(
          "refresh",
          htmltools::span("Refresh", class="button-text"),
          icon=shiny::icon("arrows-rotate"),
          title = "Refresh"
        ),
        shiny::actionButton(
          "close",
          htmltools::span("Close", class="button-text"),
          icon=shiny::icon("arrow-right-from-bracket"),
          title="Close"
        )
      ),
      htmltools::div(
        class = "bar",
        shiny::textOutput("selected_file"),
        shiny::actionButton("copy_to_clipboard", label="", icon = shiny::icon("clipboard"))
      ),
      htmltools::div(
        class = "bar",
        shiny::icon("shapes"),
        shiny::uiOutput("breadcrumbs")
      ),
      gt::gt_output("file_table")
    )
  )

  server <- function(input, output, session) {
    # This cache is used to store already browsed folders
    cache <- cachem::cache_mem()
    #cache <- cachem::cache_disk(".cache")

    # Session host
    ses_host <- shiny::reactiveVal(NULL)
    # Session token
    ses_token <- shiny::reactiveVal(NULL)
    # Session ws_id
    ses_ws_id <- shiny::reactiveVal(NULL)

    # The current folder we are browsing:
    current_dir <- shiny::reactiveVal(init_path)
    # The last selected file or folder:
    last_selected <- shiny::reactiveVal(init_path)
    # Table with file data:
    files_data <- shiny::reactiveVal(NULL)

    # Helper function to retrieve the table with files, showing a notification on error
    get_files_table_error_notif <- function(full_path) {
      shiny::req(ses_host(), ses_token())
      df <- get_files_table(full_path, cache=cache, host=ses_host(), token=ses_token())
      if (is.null(df)) {
        shiny::showNotification(paste0("Invalid directory: ", full_path), type = "error")
      } else if (nrow(df) >= 1000) {
        url <- create_databricks_url_for_path(full_path, host=ses_host(), ws_id = ses_ws_id())
        shiny::showNotification(
          htmltools::p(
            glue::glue("Reached limit of 1000 files for {basename(full_path)}. Consider browsing in "),
            htmltools::a("databricks", href=url, target="_blank"),
          ),
          type = "warning",
          duration = NULL
        )
      }
      df
    }


    # Decrypt the host and token from the passed credentials:
    shiny::observe({
      query <- shiny::parseQueryString(session$clientData$url_search)
      if (!is.null(query[['credentials']])) {
        host_token <- decrypt_credentials(query[['credentials']], key=key)
        if (is.null(host_token)) {
          shiny::showNotification("Invalid credentials", type="error")
          return()
        }
        ses_host(host_token$host)
        ses_token(host_token$token)
        ses_ws_id(db_current_workspace_id(host=host_token$host, token=host_token$token))
        current_dir(current_dir())
      }
    })

    # If we initiate a browser session with a given path, let's browse that path:
    shiny::observe({
      query <- shiny::parseQueryString(session$clientData$url_search)
      if (!is.null(query[['path']])) {
        current_dir(query[['path']])
        last_selected(query[['path']])
      }
    })

    ## The action bar:

    ### New folder button:
    shiny::observeEvent(input$new_folder_modal, {
      shiny::req(ses_host(), ses_token())
      shiny::showModal(shiny::modalDialog(
          title = "New folder",
          shiny::textInput("new_folder_name", "New folder name:", ""),
          footer = htmltools::tagList(
            shiny::modalButton("Cancel"),
            shiny::actionButton("create_folder", "Create")
          )
      ))
    })

    shiny::observeEvent(input$create_folder, {
      shiny::req(ses_host(), ses_token())
      shiny::req(input$new_folder_name)
      folder_name <- paste0(current_dir(), input$new_folder_name, "/")
      db_volume_dir_create(folder_name, host=ses_host(), token=ses_token())
      shiny::removeModal()
    })


    ### Upload file button
    shiny::observeEvent(input$upload_file, {
      # FIXME: We just open databricks in a browser.
      # TODO: Let the user choose a local file (or folder) and
      #       upload it in the background
      shiny::req(ses_host(), ses_token())
      # Currently we just open the databricks URL
      url <- create_databricks_url_for_path(full_path = current_dir(), host = ses_host(), ws_id = ses_ws_id())
      utils::browseURL(url)
    })

    ### Delete file button:
    shiny::observeEvent(input$delete, {
      shiny::req(ses_host(), ses_token())
      path <- last_selected()
      shiny::showModal(
        shiny::modalDialog(
        title = "Delete file",
        htmltools::p("Do you want to delete this file?"),
        htmltools::pre(path),
        footer = htmltools::tagList(
          shiny::modalButton("Cancel"),
          shiny::actionButton("delete_selected_file", "Delete")
        )
      ))
    })

    shiny::observeEvent(input$delete_selected_file, {
      shiny::req(ses_host(), ses_token())
      # Delete the file
      path <- last_selected()
      db_volume_delete(path = path, host=ses_host(), token=ses_token())
      shiny::removeModal()
      # Refresh the current folder, so the deleted file disappears:
      curdir <- current_dir()
      cache$remove(get_cache_key(current_dir(), host=ses_host(), token=ses_token()))
      files_data(get_files_table_error_notif(current_dir()))
      # Inform the user:
      shiny::showNotification(paste0("File ", basename(path), " deleted"))
    })

    ### Copy to clipboard button
    shiny::observeEvent(input$copy_to_clipboard, {
      shiny::req(ses_host(), ses_token())
      path <- last_selected()
      utils::writeClipboard(path, format = 13)
      shiny::showNotification("Copied!", type = "default")
    })

    ### Open in databricks button
    shiny::observeEvent(input$open_in_databricks, {
      shiny::req(ses_host(), ses_token())
      url <- create_databricks_url_for_path(
        current_dir(),
        host = ses_host(),
        ws_id = ses_ws_id()
      )
      utils::browseURL(url)
    })

    ### Go to path button
    shiny::observeEvent(input$go_to_path, {
      shiny::req(ses_host(), ses_token())
      shiny::showModal(shiny::modalDialog(
        title = "Go to path",
        shiny::textInput("go_to_path_name", "Path:", ""),
        footer = htmltools::tagList(
          shiny::modalButton("Cancel"),
          shiny::actionButton("go_to_path_exec", "Browse")
        )
      ))
    })


    shiny::observeEvent(input$go_to_path_exec, {
      shiny::req(ses_host(), ses_token())
      shiny::req(input$go_to_path_name)
      if (!startsWith(input$go_to_path_name, "/Volumes")) {
        shiny::showNotification("Invalid path", type="error")
        return()
      }
      current_dir(input$go_to_path_name)
      last_selected(input$go_to_path_name)
      shiny::removeModal()
    })


    ### Refresh button:
    shiny::observeEvent(input$refresh, {
      shiny::req(ses_host(), ses_token())
      cache$reset()
      files_data(get_files_table_error_notif(current_dir()))
    })

    ### Close/Exit button:
    shiny::observeEvent(input$close, {
      shiny::req(ses_host(), ses_token())
      shiny::stopApp()
    })


    # Breadcrumb UI
    output$breadcrumbs <- shiny::renderUI({
      shiny::req(ses_host(), ses_token())
      path <- current_dir()
      # Splits the path and creates a link for each parent folder
      parts <- strsplit(path, "/")[[1]]
      crumbs <- lapply(seq_along(parts), function(i) {
        # There is nothing before the first "/", skip this:
        if (i == 1) {
          return(NULL)
        }
        # This link label:
        if (i == 2) {
          label <- paste0("/", parts[i], "/")
        } else {
          label <- paste0(parts[i], "/")
        }
        # Points to this folder:
        subpath <- paste0(c(parts[1:i], ""), collapse="/")
        # Create a link
        htmltools::HTML(create_folder_link(label, subpath))
      })
      do.call(htmltools::tagList, crumbs)
    })

    # If current_dir changes,
    #  Enable/disable folder creation
    #  And update the files_data variable
    shiny::observeEvent(current_dir(),
      {
      x <- fullpath_to_pathcomponents(current_dir())
      if (is.null(x$volume)) {
        shinyjs::disable("new_folder_modal")
        shinyjs::disable("upload_file")
        shinyjs::disable("delete")
      } else {
        shinyjs::enable("new_folder_modal")
        shinyjs::enable("upload_file")
        shinyjs::enable("delete")
      }
      files_data(get_files_table_error_notif(current_dir()))
    })


    # If the files table changes, render it in a nice way
    output$file_table <- gt::render_gt({
      shiny::req(ses_host(), ses_token())
      # Get the table with file entries:
      df <- files_data()
      shiny::req(df)
      # Get an icon for each object type:
      icons <- purrr::map_chr(df$ObjectType, function(type) {
        icon_name <- switch(type, CATALOG = "book", SCHEMA = "database",
                            TABLE = "table", VOLUME = "folder", DIRECTORY = "folder",
                            FILE = "file", UP = "circle-left")
        as.character(shiny::icon(icon_name))
      })

      # Prepend the icon column:
      df <- cbind(icon = I(icons), df)

      # Turn the Name into a link
      df$Name <- ifelse(
        df$ObjectType %in% c("CATALOG", "SCHEMA", "VOLUME", "DIRECTORY", "UP"),
        purrr::map2_chr(df$Name, df$FullPath, create_folder_link),
        purrr::map2_chr(df$Name, df$FullPath, select_file_link)
      )

      # Drop these two columns, we don't need to display them:
      df$FullPath <- NULL
      df$ObjectType <- NULL

      # Display settings
      df |>
        gt::gt() |>
        gt::sub_missing(columns=c("Size", "Modified"), missing_text="") |>
        gt::fmt_bytes(columns = "Size") |>
        gt::fmt_passthrough(columns = "Name", escape = FALSE) |>
        gt::fmt_datetime(columns="Modified", date_style = "iso", time_style = "iso-short") |>
        gt::cols_align(columns="Modified", align="left") |>
        gt::tab_options(table.align = "left") |>
        gt::opt_vertical_padding(scale = 0.25)
    })


    # If user clicks folder, then get the destination path, navigate and set
    # it as to be copied to clipboard
    shiny::observeEvent(input$clicked_folder, {
      shiny::req(ses_host(), ses_token())
      # Reverse operation from create_folder_link
      full_path <- rawToChar(openssl::base64_decode(input$clicked_folder))
      current_dir(full_path)
      last_selected(full_path)
    })

    # If user clicks on a file, set it for being copied to clipboard
    shiny::observeEvent(input$clicked_file, {
      shiny::req(ses_host(), ses_token())
      full_path <- rawToChar(openssl::base64_decode(input$clicked_file))
      last_selected(full_path)
    })

    # Print on screen the last file or folder that was selected
    output$selected_file <- shiny::renderText({
      shiny::req(ses_host(), ses_token())
      path <- last_selected()
      shiny::req(path)
      path
    })

    # Required event for all gadgets executed through runGadget:
    shiny::observeEvent(input$done, {
      shiny::stopApp()
    })
  }
  list(ui=ui, server=server)
}


# In order for the browser volume to work on the Viewer pane and keep R
# responsive, we need to start the shiny app as a background job.
# We just want one instance of the shiny app running, so we need a
# singleton object to hold it:
vol_browser_singleton <- new.env(parent = emptyenv())

# Helper function to check if the volume browser is alive:
is_vol_browser_alive <- function() {
  (!is.null(vol_browser_singleton$app)) && vol_browser_singleton$app$is_alive()
}


# Helper function to get a random port for the shiny app. We need to know
# the port to browse it, so it is easier for us to pick a port than to figure out
# how to get the random port shiny picked in the background process.
get_random_port <- function() {
  # get a random port number from a reasonable set.
  # see the port argument in `?shiny::runApp`
  excluded_ports <- c(3659, 4045, 5060, 5061, 6000, 6566, 6665:6669, 6697)
  potential_ports <- setdiff(3000:8000, excluded_ports)
  sample(potential_ports, 1)
}

start_volume_browser_app <- function(path="/Volumes/") {
  # Generate a random key.
  # This key will be used to symmetrically encrypt your access token between your
  # web browser (or the rstudio panel) and the shiny server on localhost.
  if (is.null(vol_browser_singleton$key)) {
    vol_browser_singleton$key <- openssl::aes_keygen(length=32)
  }

  # Start the volume browser app if needed:
  retry_ports <- 20
  while (!is_vol_browser_alive() && retry_ports > 0) {
    # Try one port:
    if (!is.null(vol_browser_singleton$port)) {
      port <- vol_browser_singleton$port
      vol_browser_singleton$port <- NULL
    } else {
      port <- get_random_port()
    }

    # Start the app:
    vol_browser_singleton$app <- callr::r_bg(
      func = function(app, port) {
        requireNamespace("brickster")
        shiny::runApp(
          appDir = app,
          port = port
        )
      },
      args = list(
        app = volume_browser_app(
          init_path = path,
          key = vol_browser_singleton$key
        ),
        port = port
      )
    )

    # Check success, save port
    if (vol_browser_singleton$app$is_alive()) {
      vol_browser_singleton$port <- port
      break
    }
    # We failed, retry:
    retry_ports <- retry_ports - 1
  }
  if (retry_ports == 0) {
    stop(
      "Could not start the volume browser shiny app. Error log: \n\n",
      vol_browser_singleton$app$read_all_error()
    )
  }
  list(
    port = vol_browser_singleton$port,
    key = vol_browser_singleton$key
  )
}

stop_volume_browser_app <- function() {
  if (!is_vol_browser_alive()) {
    return()
  }
  vol_browser_singleton$app$kill()
}


build_volume_browser_url <- function(path, host = db_host(), token = db_token(), port=NULL, key=NULL) {
  if ((is.null(port) || is.null(key)) && !is_vol_browser_alive()) {
    start_volume_browser_app()
  }

  if (is.null(port)) {
    port <- vol_browser_singleton$port
  }
  if (is.null(key)) {
    key <- vol_browser_singleton$key
  }
  credentials <- encrypt_credentials(host = host, token = token, key = key)
  path_enc <- utils::URLencode(path, reserved=TRUE)
  url <- glue::glue("http://localhost:{port}?path={path_enc}&credentials={credentials}")
  url
}

# nocov start
# No coverage because this function is interactive

#' Browse a Unity Catalog path
#'
#' Opens a browser in the RStudio viewer
#' @param path The initial path to browse
#' @inheritParams db_dbfs_create
#' @returns An invisible `NULL`.
#' @export
browse_path <- function(path = "/Volumes/", host=db_host(), token = db_token()) {
  start_volume_browser_app(path=path)
  url <- build_volume_browser_url(path=path, host=host, token=token)
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    rstudioapi::viewer(url=url)
  } else {
    utils::browseURL(url)
  }
  invisible(NULL)
}
# nocov end

# nocov start
# No coverage because this function is just meant to be used
# to ease development
#
# Browse a path without using the background shiny app.
# Useful for developing the shiny app
# brickster:::browse_path_foreground()
browse_path_foreground <- function(use_panel=TRUE) {
  key <- openssl::aes_keygen(length=32)
  port <- 5000
  app <- volume_browser_app(init_path="/Volumes/", key=key)
  url <- build_volume_browser_url(
    path="/Volumes/",
    host=db_host(),
    token = db_token(),
    port=port,
    key=key
    )
  cli::cli_text("Access the volume browser with: {.url {url}}")
  shiny::runApp(app, port=port, launch.browser = FALSE)
}
# nocov end
