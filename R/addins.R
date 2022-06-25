clusters_and_endpoints_widget <- function() {
  get_cluster_infos <- function() {
    clusters <- brickster::db_cluster_list()
    purrr::map_dfr(clusters$clusters, ~ {
      list(
        id = .x$cluster_id,
        name = .x$cluster_name,
        driver = .x$driver_node_type_id,
        workers = .x$node_type_id,
        num_workers = length(.x$executors),
        state = .x$state,
        creator = .x$creator_user_name
      )
    })
  }

  get_endpoint_infos <- function() {
    endpoints <- brickster::db_sql_warehouse_list()
    purrr::map_dfr(endpoints$endpoints, ~ {
      list(
        id = .x$id,
        name = .x$name,
        size = .x$cluster_size,
        state = .x$state,
        photon = .x$enable_photon,
        serverless = .x$enable_serverless_compute,
        creator = .x$creator_name
      )
    })
  }


  ui <- miniUI::miniPage(
    shiny::tags$head(
      # Note the wrapping of the string in HTML()
      shiny::tags$style(shiny::HTML("
        table.dataTable tbody th, table.dataTable tbody td {
          padding: 2px 5px !important;
        }
      "))
    ),
    miniUI::gadgetTitleBar(
      title = "Databricks Compute",
      right = shiny::actionButton("refresh", "Refresh")
    ),
    miniUI::miniTabstripPanel(
      id = "tabs",
      between = miniUI::miniButtonBlock(
        shiny::actionButton("insert_id", "Insert ID"),
        shiny::actionButton("open_in_db", "View in Databricks")
      ),
      miniUI::miniTabPanel(
        value = "cluster",
        title = "Clusters",
        icon = shiny::icon("desktop"),
        miniUI::miniContentPanel(
          DT::dataTableOutput("cluster_tbl")
        )
      ),
      miniUI::miniTabPanel(
        value = "endpoint",
        title = "Endpoints",
        icon = shiny::icon("cloud"),
        miniUI::miniContentPanel(
          DT::dataTableOutput("endpoint_tbl")
        )
      )
    )
  )

  server <- function(input, output, session) {
    last_selected_id <- shiny::reactiveVal(NULL)

    # data
    clusters <- shiny::eventReactive(input$refresh,
      {
        get_cluster_infos()
      },
      ignoreNULL = FALSE
    )

    endpoints <- shiny::eventReactive(input$refresh,
      {
        get_endpoint_infos()
      },
      ignoreNULL = FALSE
    )

    # render
    output$cluster_tbl <- DT::renderDataTable(
      {
        clusters()[, -1]
      },
      selection = "single",
      options = list(dom = "ft", pageLength = 10)
    )

    output$endpoint_tbl <- DT::renderDataTable(
      {
        endpoints()[, -1]
      },
      selection = "single",
      options = list(dom = "ft", pageLength = 10)
    )

    # observers
    shiny::observe({
      last_selected_id(
        list(type = "cluster", id = clusters()$id[input$cluster_tbl_rows_selected])
      )
    })
    shiny::observe({
      last_selected_id(
        list(type = "endpoint", id = endpoints()$id[input$endpoint_tbl_rows_selected])
      )
    })

    # triggers
    shiny::observeEvent(input$insert_id, {
      shiny::req(last_selected_id())
      rstudioapi::insertText(last_selected_id()$id)
      shiny::stopApp()
    })

    shiny::observeEvent(input$open_in_db, {
      shiny::req(last_selected_id())
      if (last_selected_id()$type == "endpoint") {
        url <- paste0(Sys.getenv("DATABRICKS_HOST"), "sql/endpoints/", last_selected_id()$id)
      } else {
        url <- paste0(Sys.getenv("DATABRICKS_HOST"), "?o=#setting/clusters/", last_selected_id()$id, "/congifuration")
      }
      utils::browseURL(url)
    })
  }

  viewer <- shiny::paneViewer(300)
  shiny::runGadget(ui, server, viewer = viewer)
}
