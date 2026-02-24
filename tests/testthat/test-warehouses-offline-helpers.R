test_that("get_and_start_warehouse starts stopped warehouses", {
  state <- new.env(parent = emptyenv())
  state$idx <- 0L
  state$start_calls <- 0L
  states <- list(
    list(state = "STOPPED"),
    list(state = "STARTING"),
    list(state = "RUNNING")
  )

  local_mocked_bindings(
    db_sql_warehouse_get = function(...) {
      state$idx <- state$idx + 1L
      states[[state$idx]]
    },
    db_sql_warehouse_start = function(...) {
      state$start_calls <- state$start_calls + 1L
      list()
    },
    .package = "brickster"
  )

  out <- get_and_start_warehouse(id = "wh-1", polling_interval = 0)
  expect_identical(state$start_calls, 1L)
  expect_identical(state$idx, 3L)
  expect_identical(out$state, "RUNNING")
})

test_that("get_and_start_warehouse skips already running warehouses", {
  state <- new.env(parent = emptyenv())
  state$start_calls <- 0L

  local_mocked_bindings(
    db_sql_warehouse_get = function(...) list(state = "RUNNING"),
    db_sql_warehouse_start = function(...) {
      state$start_calls <- state$start_calls + 1L
      list()
    },
    .package = "brickster"
  )

  out_running <- get_and_start_warehouse(id = "wh-2", polling_interval = 0)
  expect_identical(out_running$state, "RUNNING")
  expect_identical(state$start_calls, 0L)
})

test_that("warehouse get/list responses add print classes without changing list access", {
  withr::local_envvar(c(
    "DATABRICKS_HOST" = "http://mock_host",
    "DATABRICKS_TOKEN" = "mock_token"
  ))

  local_mocked_bindings(
    db_request = function(...) {
      args <- list(...)
      structure(list(endpoint = args$endpoint), class = "httr2_request")
    },
    db_perform_request = function(req) {
      if (identical(req$endpoint, "sql/warehouses")) {
        return(list(
          warehouses = list(
            list(
              id = "wh-1",
              name = "warehouse-a",
              state = "RUNNING",
              cluster_size = "2X-Small",
              num_clusters = 1,
              min_num_clusters = 1,
              max_num_clusters = 1,
              warehouse_type = "PRO"
            ),
            list(
              id = "wh-2",
              name = "warehouse-b",
              state = "STOPPED",
              cluster_size = "Small",
              num_clusters = 2,
              min_num_clusters = 1,
              max_num_clusters = 3,
              warehouse_type = "CLASSIC"
            )
          )
        ))
      }

      if (identical(req$endpoint, "sql/warehouses/wh-1")) {
        return(list(
          id = "wh-1",
          name = "warehouse-a",
          state = "RUNNING",
          cluster_size = "2X-Small",
          num_clusters = 1,
          min_num_clusters = 1,
          max_num_clusters = 1,
          warehouse_type = "PRO"
        ))
      }

      cli::cli_abort("Unexpected endpoint in test mock: {req$endpoint}")
    },
    .package = "brickster"
  )

  warehouse <- db_sql_warehouse_get(id = "wh-1", perform_request = TRUE)
  warehouses <- db_sql_warehouse_list(perform_request = TRUE)

  expect_type(warehouse, "list")
  expect_s3_class(warehouse, c("db_sql_warehouse", "list"))
  expect_identical(warehouse$id, "wh-1")

  expect_type(warehouses, "list")
  expect_s3_class(warehouses, c("db_sql_warehouse_list", "list"))
  expect_s3_class(warehouses[[1]], c("db_sql_warehouse", "list"))
  expect_identical(warehouses[[2]]$id, "wh-2")

  warehouse_print <- cli::ansi_strip(paste(capture.output(print(warehouse)), collapse = "\n"))
  warehouses_print <- cli::ansi_strip(paste(capture.output(print(warehouses)), collapse = "\n"))

  expect_true(grepl("warehouse wh-1", warehouse_print, fixed = TRUE))
  expect_true(grepl("\n  warehouse-a\n", warehouse_print, fixed = TRUE))
  expect_true(grepl("\n  Type: Pro\n", warehouse_print, fixed = TRUE))
  expect_true(grepl("\n  Size: 2X-Small [1/1]\n", warehouse_print, fixed = TRUE))
  expect_true(grepl("[[1]]", warehouses_print, fixed = TRUE))
  expect_true(grepl("warehouse wh-1", warehouses_print, fixed = TRUE))
  expect_true(grepl("warehouse wh-2", warehouses_print, fixed = TRUE))
  expect_true(grepl("\n  Type: Classic\n", warehouses_print, fixed = TRUE))
  expect_true(grepl("\n  Size: Small [2/1-3]\n", warehouses_print, fixed = TRUE))
})

test_that("warehouse print shows type as Serverless, Pro, or Classic", {
  warehouse_serverless <- structure(
    list(
      id = "wh-s",
      name = "warehouse-serverless",
      state = "RUNNING",
      cluster_size = "Small",
      num_clusters = 1,
      min_num_clusters = 1,
      max_num_clusters = 1,
      warehouse_type = "PRO",
      enable_serverless_compute = TRUE
    ),
    class = c("db_sql_warehouse", "list")
  )

  warehouse_pro <- structure(
    list(
      id = "wh-p",
      name = "warehouse-pro",
      state = "RUNNING",
      cluster_size = "Small",
      num_clusters = 1,
      min_num_clusters = 1,
      max_num_clusters = 1,
      warehouse_type = "PRO",
      enable_serverless_compute = FALSE
    ),
    class = c("db_sql_warehouse", "list")
  )

  warehouse_classic <- structure(
    list(
      id = "wh-c",
      name = "warehouse-classic",
      state = "RUNNING",
      cluster_size = "Small",
      num_clusters = 1,
      min_num_clusters = 1,
      max_num_clusters = 1,
      warehouse_type = "CLASSIC",
      enable_serverless_compute = FALSE
    ),
    class = c("db_sql_warehouse", "list")
  )

  serverless_print <- cli::ansi_strip(
    paste(capture.output(print(warehouse_serverless)), collapse = "\n")
  )
  pro_print <- cli::ansi_strip(
    paste(capture.output(print(warehouse_pro)), collapse = "\n")
  )
  classic_print <- cli::ansi_strip(
    paste(capture.output(print(warehouse_classic)), collapse = "\n")
  )

  expect_true(grepl("\n  Type: Serverless\n", serverless_print, fixed = TRUE))
  expect_true(grepl("\n  Type: Pro\n", pro_print, fixed = TRUE))
  expect_true(grepl("\n  Type: Classic\n", classic_print, fixed = TRUE))
  expect_true(grepl("\n  Size: Small [1/1]\n", serverless_print, fixed = TRUE))
  expect_true(grepl("\n  Size: Small [1/1]\n", pro_print, fixed = TRUE))
  expect_true(grepl("\n  Size: Small [1/1]\n", classic_print, fixed = TRUE))
})
