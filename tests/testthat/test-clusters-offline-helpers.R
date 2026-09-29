test_that("cluster listing preserves metadata and exposes subsequent pages", {
  state <- new.env(parent = emptyenv())
  state$tokens <- list()
  local_mocked_bindings(
    db_perform_request = function(req) {
      token <- httr2::url_parse(req$url)$query$page_token
      state$tokens[length(state$tokens) + 1L] <- list(token)
      if (is.null(token)) {
        return(list(
          clusters = list(list(cluster_id = "first")), next_page_token = "next+/=",
          prev_page_token = "previous", future_metadata = "kept"
        ))
      }
      if (token == "next+/=") return(list(next_page_token = "last", future_metadata = "empty page"))
      list(clusters = list(list(cluster_id = "last")), next_page_token = "")
    },
    .package = "brickster"
  )
  first <- db_cluster_list("mock_host", "mock_token")
  expect_s3_class(first, "db_cluster_list")
  expect_s3_class(first$clusters[[1]], "db_cluster")
  expect_identical(first$clusters[[1]]$cluster_id, "first")
  expect_identical(first$next_page_token, "next+/=")
  expect_identical(first$prev_page_token, "previous")
  expect_identical(first$future_metadata, "kept")
  expect_length(state$tokens, 1L)
  second <- db_cluster_list("mock_host", "mock_token", page_token = first$next_page_token)
  expect_null(second$clusters)
  expect_identical(second$future_metadata, "empty page")
  last <- db_cluster_list("mock_host", "mock_token", page_token = second$next_page_token)
  expect_identical(last$clusters[[1]]$cluster_id, "last")
  expect_identical(last$next_page_token, "")
  expect_identical(state$tokens, list(NULL, "next+/=", "last"))
})

test_that("events preserve pagination tokens and filters across requests", {
  state <- new.env(parent = emptyenv())
  state$bodies <- list()
  local_mocked_bindings(
    db_perform_request = function(req) {
      state$bodies[[length(state$bodies) + 1L]] <- req$body$data
      if (is.null(req$body$data$page_token)) {
        return(list(events = list(list(type = "RUNNING")), next_page_token = "next+/=", prev_page_token = "previous"))
      }
      list(events = list(), next_page_token = "", prev_page_token = "first", future_metadata = "kept")
    },
    .package = "brickster"
  )
  args <- list(
    cluster_id = "c-1", start_time = 1790553600000, end_time = 1790640000000,
    event_types = list("RUNNING"), order = "ASC", page_size = 10,
    host = "mock_host", token = "mock_token"
  )
  first <- do.call(db_cluster_events, args)
  expect_identical(first$events[[1]]$type, "RUNNING")
  expect_identical(first$next_page_token, "next+/=")
  expect_identical(first$prev_page_token, "previous")
  expect_length(state$bodies, 1L)
  last <- do.call(db_cluster_events, c(args, list(page_token = first$next_page_token)))
  expect_identical(last, list(events = list(), next_page_token = "", prev_page_token = "first", future_metadata = "kept"))
  expect_identical(state$bodies[[2]], c(state$bodies[[1]], list(page_token = "next+/=")))
})

test_that("empty cluster and event responses remain usable", {
  local_mocked_bindings(db_perform_request = function(req) list(), .package = "brickster")
  page <- db_cluster_list("mock_host", "mock_token")
  expect_identical(unclass(page), list())
  expect_output(expect_identical(print(page), page), "NULL")
  expect_identical(db_cluster_events("c-1", host = "mock_host", token = "mock_token"), list())
})

test_that("get_and_start_cluster starts a terminated cluster and waits until running", {
  state <- new.env(parent = emptyenv())
  state$idx <- 0L
  state$started <- FALSE
  states <- list(
    list(state = "TERMINATED", state_message = "terminated", cluster_name = "test-cluster"),
    list(state = "PENDING", state_message = "starting", cluster_name = "test-cluster"),
    list(state = "RUNNING", state_message = "running", cluster_name = "test-cluster")
  )

  local_mocked_bindings(
    db_cluster_get = function(...) {
      state$idx <- state$idx + 1L
      states[[state$idx]]
    },
    db_cluster_start = function(...) {
      state$started <- TRUE
      list()
    },
    .package = "brickster"
  )

  out <- get_and_start_cluster(cluster_id = "abc", polling_interval = 0, silent = TRUE)

  expect_true(state$started)
  expect_identical(state$idx, 3L)
  expect_identical(out$state, "RUNNING")
})

test_that("get_and_start_cluster does not start an already-running cluster", {
  state <- new.env(parent = emptyenv())
  state$start_calls <- 0L

  local_mocked_bindings(
    db_cluster_get = function(...) {
      list(state = "RUNNING", state_message = "ready", cluster_name = "test-cluster")
    },
    db_cluster_start = function(...) {
      state$start_calls <- state$start_calls + 1L
      list()
    },
    .package = "brickster"
  )

  out <- get_and_start_cluster(cluster_id = "abc", polling_interval = 0, silent = TRUE)

  expect_identical(state$start_calls, 0L)
  expect_identical(out$state, "RUNNING")
})

test_that("get_and_start_cluster exits when cluster enters terminating state", {
  state <- new.env(parent = emptyenv())
  state$idx <- 0L
  state$started <- FALSE
  states <- list(
    list(state = "TERMINATED", state_message = "terminated", cluster_name = "test-cluster"),
    list(state = "TERMINATING", state_message = "terminating", cluster_name = "test-cluster")
  )

  local_mocked_bindings(
    db_cluster_get = function(...) {
      state$idx <- state$idx + 1L
      states[[state$idx]]
    },
    db_cluster_start = function(...) {
      state$started <- TRUE
      list()
    },
    .package = "brickster"
  )

  out <- get_and_start_cluster(cluster_id = "abc", polling_interval = 0, silent = TRUE)

  expect_true(state$started)
  expect_identical(out$state, "TERMINATING")
})

test_that("get_latest_dbr selects expected runtime based on flags", {
  runtimes <- list(
    versions = list(
      list(key = "14.2.x-scala2.12", name = "14.2"),
      list(key = "14.3.x-scala2.12", name = "14.3"),
      list(key = "14.3.x-cpu-ml-scala2.12", name = "14.3 ML"),
      list(key = "14.3.x-gpu-ml-scala2.12", name = "14.3 ML GPU"),
      list(key = "14.3.x-photon-scala2.12", name = "14.3 Photon"),
      list(key = "13.3.x-scala2.12", name = "13.3 LTS"),
      list(key = "13.3.x-cpu-ml-scala2.12", name = "13.3 ML LTS")
    )
  )

  local_mocked_bindings(
    db_cluster_runtime_versions = function(...) runtimes,
    .package = "brickster"
  )

  out_std <- get_latest_dbr(lts = FALSE, ml = FALSE, gpu = FALSE, photon = FALSE)
  out_ml_lts <- get_latest_dbr(lts = TRUE, ml = TRUE, gpu = FALSE, photon = FALSE)
  out_photon <- get_latest_dbr(lts = FALSE, ml = FALSE, gpu = FALSE, photon = TRUE)

  expect_identical(out_std$key, "14.3.x-scala2.12")
  expect_identical(out_ml_lts$key, "13.3.x-cpu-ml-scala2.12")
  expect_identical(out_photon$key, "14.3.x-photon-scala2.12")
})

test_that("get_latest_dbr rejects invalid runtime flag combinations", {
  expect_error(
    get_latest_dbr(lts = FALSE, ml = FALSE, gpu = TRUE, photon = FALSE),
    "gpu"
  )

  expect_error(
    get_latest_dbr(lts = TRUE, ml = TRUE, gpu = FALSE, photon = TRUE),
    "Cannot use"
  )
})

test_that("cluster create/edit wrappers validate cloud attrs and include autoscale bodies", {
  withr::local_envvar(c(
    "DATABRICKS_HOST" = "http://mock_host",
    "DATABRICKS_TOKEN" = "mock_token"
  ))

  req <- structure(list(), class = "httr2_request")
  state <- new.env(parent = emptyenv())
  state$create_body <- NULL
  state$edit_body <- NULL

  expect_error(
    db_cluster_create(
      name = "x",
      spark_version = "14.3.x-scala2.12",
      node_type_id = "m5d.large",
      num_workers = 1,
      cloud_attrs = list(bad = TRUE),
      perform_request = FALSE
    ),
    "Invalid cloud attributes specification"
  )

  local_mocked_bindings(
    db_request = function(...) {
      args <- list(...)
      endpoint <- args$endpoint
      if (identical(endpoint, "clusters/create")) {
        state$create_body <- args$body
      }
      if (identical(endpoint, "clusters/edit")) {
        state$edit_body <- args$body
      }
      req
    },
    db_perform_request = function(req) {
      if (!is.null(state$create_body) && is.null(state$edit_body)) {
        return(list(cluster_id = "c-1"))
      }
      list(ok = TRUE)
    },
    .package = "brickster"
  )

  create_out <- db_cluster_create(
    name = "c",
    spark_version = "14.3.x-scala2.12",
    node_type_id = "m5d.large",
    autoscale = cluster_autoscale(1, 2),
    cloud_attrs = azure_attributes(),
    log_conf = cluster_log_conf(dbfs = dbfs_storage_info("dbfs:/logs")),
    perform_request = TRUE
  )

  expect_identical(create_out$cluster_id, "c-1")
  expect_true(!is.null(state$create_body$autoscale))
  expect_true(!is.null(state$create_body$azure_attributes))
  expect_identical(
    state$create_body$cluster_log_conf$dbfs$destination,
    "dbfs:/logs"
  )
  expect_null(state$create_body$log_conf)

  expect_error(
    db_cluster_edit(
      cluster_id = "c-1",
      spark_version = "14.3.x-scala2.12",
      node_type_id = "m5d.large",
      cloud_attrs = gcp_attributes(),
      perform_request = FALSE
    ),
    "Invalid cloud attributes specification"
  )

  edit_out <- db_cluster_edit(
    cluster_id = "c-1",
    spark_version = "14.3.x-scala2.12",
    node_type_id = "m5d.large",
    autoscale = cluster_autoscale(2, 4),
    cloud_attrs = azure_attributes(),
    log_conf = cluster_log_conf(dbfs = dbfs_storage_info("dbfs:/logs")),
    perform_request = TRUE
  )

  expect_true(edit_out$ok)
  expect_true(!is.null(state$edit_body$autoscale))
  expect_true(!is.null(state$edit_body$azure_attributes))
  expect_identical(
    state$edit_body$cluster_log_conf$dbfs$destination,
    "dbfs:/logs"
  )
  expect_null(state$edit_body$log_conf)
})

test_that("cluster action/list wrappers return expected payload shapes", {
  withr::local_envvar(c(
    "DATABRICKS_HOST" = "http://mock_host",
    "DATABRICKS_TOKEN" = "mock_token"
  ))

  local_mocked_bindings(
    db_perform_response = function(req) list(),
    db_perform_request = function(req) {
      list(
        cluster_id = "c-1",
        clusters = list(list(cluster_id = "c-1")),
        node_types = list(list(node_type_id = "m5d.large")),
        versions = list(list(key = "14.3.x-scala2.12")),
        zones = c("us-west-2a"),
        events = list(list(type = "RUNNING"))
      )
    },
    .package = "brickster"
  )
  expect_null(db_cluster_action(cluster_id = "c-1", action = "start", perform_request = TRUE))

  expect_identical(db_cluster_list(perform_request = TRUE)$clusters[[1]]$cluster_id, "c-1")
  expect_identical(db_cluster_list_node_types(perform_request = TRUE)$node_types[[1]]$node_type_id, "m5d.large")
  expect_identical(db_cluster_runtime_versions(perform_request = TRUE)$versions[[1]]$key, "14.3.x-scala2.12")
  expect_identical(db_cluster_list_zones(perform_request = TRUE)$zones, "us-west-2a")
  expect_identical(db_cluster_events(cluster_id = "c-1", perform_request = TRUE)$events[[1]]$type, "RUNNING")
  expect_identical(db_cluster_get(cluster_id = "c-1", perform_request = TRUE)$cluster_id, "c-1")
})

test_that("cluster get/list responses retain print classes and cluster details", {
  withr::local_envvar(c(
    "DATABRICKS_HOST" = "http://mock_host",
    "DATABRICKS_TOKEN" = "mock_token"
  ))

  local_mocked_bindings(
    db_perform_request = function(req) {
      endpoint <- httr2::url_parse(req$url)$path
      if (endsWith(endpoint, "/clusters/list")) {
        return(list(
          clusters = list(
            list(
              cluster_id = "c-1",
              cluster_name = "cluster-a",
              state = "RUNNING",
              num_workers = 2,
              release_version = "14.3",
              runtime_engine = "PHOTON",
              executors = list(list(executor_id = "1"), list(executor_id = "2")),
              node_type_id = "m5d.large",
              spark_version = "14.3.x-scala2.12"
            ),
            list(
              cluster_id = "c-2",
              cluster_name = "cluster-b",
              state = "TERMINATED",
              autoscale = list(min_workers = 1, max_workers = 3),
              release_version = "14.2",
              node_type_id = "m5d.xlarge",
              spark_version = "14.2.x-scala2.12"
            )
          )
        ))
      }

      if (endsWith(endpoint, "/clusters/get")) {
        return(
          list(
            cluster_id = "c-1",
            cluster_name = "cluster-a",
            state = "RUNNING",
            num_workers = 2,
            release_version = "14.3",
            runtime_engine = "PHOTON",
            executors = list(list(executor_id = "1"), list(executor_id = "2")),
            node_type_id = "m5d.large",
            spark_version = "14.3.x-scala2.12"
          )
        )
      }

      cli::cli_abort("Unexpected endpoint in test mock: {endpoint}")
    },
    .package = "brickster"
  )

  cluster <- db_cluster_get(cluster_id = "c-1", perform_request = TRUE)
  clusters <- db_cluster_list(perform_request = TRUE)

  expect_type(cluster, "list")
  expect_s3_class(cluster, c("db_cluster", "list"))
  expect_identical(cluster$cluster_id, "c-1")

  expect_type(clusters, "list")
  expect_s3_class(clusters, c("db_cluster_list", "list"))
  expect_s3_class(clusters$clusters[[1]], c("db_cluster", "list"))
  expect_identical(clusters$clusters[[2]]$cluster_id, "c-2")

  cluster_print <- cli::ansi_strip(paste(capture.output(print(cluster)), collapse = "\n"))
  clusters_print <- cli::ansi_strip(paste(capture.output(print(clusters)), collapse = "\n"))

  expect_true(grepl("cluster c-1", cluster_print, fixed = TRUE))
  expect_true(grepl("\n  cluster-a\n", cluster_print, fixed = TRUE))
  expect_true(grepl("Runtime: 14.3 Photon", cluster_print, fixed = TRUE))
  expect_true(grepl("Node Type: m5d.large [2/2]", cluster_print, fixed = TRUE))
  expect_true(grepl("State: RUNNING", cluster_print, fixed = TRUE))
  expect_true(grepl("[[1]]", clusters_print, fixed = TRUE))
  expect_true(grepl("cluster c-1", clusters_print, fixed = TRUE))
  expect_true(grepl("cluster c-2", clusters_print, fixed = TRUE))
  expect_true(grepl("Runtime: 14.2", clusters_print, fixed = TRUE))
  expect_true(grepl("Node Type: m5d.xlarge [?/1-3]", clusters_print, fixed = TRUE))
  expect_true(grepl("State: TERMINATED", clusters_print, fixed = TRUE))
})

test_that("cluster print shows worker and driver node types when different", {
  cluster <- structure(
    list(
      cluster_id = "c-1",
      cluster_name = "cluster-a",
      state = "RUNNING",
      num_workers = 2,
      release_version = "14.3",
      node_type_id = "m5d.large",
      driver_node_type_id = "m5d.xlarge",
      spark_version = "14.3.x-scala2.12"
    ),
    class = c("db_cluster", "list")
  )

  cluster_print <- cli::ansi_strip(paste(capture.output(print(cluster)), collapse = "\n"))

  expect_true(grepl("Runtime: 14.3", cluster_print, fixed = TRUE))
  expect_true(grepl("Nodes [2/2]:", cluster_print, fixed = TRUE))
  expect_true(grepl("Driver: m5d.xlarge", cluster_print, fixed = TRUE))
  expect_true(grepl("Workers: m5d.large", cluster_print, fixed = TRUE))
  expect_false(grepl("Node Type:", cluster_print, fixed = TRUE))
})

test_that("cluster print clearly labels single-node clusters", {
  cluster <- structure(
    list(
      cluster_id = "c-1",
      cluster_name = "single-node-cluster",
      state = "RUNNING",
      num_workers = 0,
      node_type_id = "m5d.large",
      spark_version = "14.3.x-scala2.12",
      is_single_node = TRUE
    ),
    class = c("db_cluster", "list")
  )

  cluster_print <- cli::ansi_strip(paste(capture.output(print(cluster)), collapse = "\n"))

  expect_true(grepl("Node Type: m5d.large [single-node]", cluster_print, fixed = TRUE))
  expect_true(grepl("[single-node]", cluster_print, fixed = TRUE))
  expect_false(grepl("[0/0]", cluster_print, fixed = TRUE))
})

test_that("cluster print does not infer single-node from worker count alone", {
  cluster <- structure(
    list(
      cluster_id = "c-1",
      cluster_name = "zero-workers-cluster",
      state = "PENDING",
      num_workers = 0,
      node_type_id = "m5d.large",
      spark_version = "14.3.x-scala2.12"
    ),
    class = c("db_cluster", "list")
  )

  cluster_print <- cli::ansi_strip(paste(capture.output(print(cluster)), collapse = "\n"))

  expect_false(grepl("[single-node]", cluster_print, fixed = TRUE))
  expect_true(grepl("[0/0]", cluster_print, fixed = TRUE))
})

test_that("cluster print uses executor list length as current workers", {
  cluster <- structure(
    list(
      cluster_id = "c-1",
      cluster_name = "autoscaling-cluster",
      state = "RUNNING",
      num_workers = 5,
      autoscale = list(min_workers = 1, max_workers = 10),
      executors = list(
        list(executor_id = "1"),
        list(executor_id = "2"),
        list(executor_id = "3")
      ),
      release_version = "14.3",
      node_type_id = "m5d.large"
    ),
    class = c("db_cluster", "list")
  )

  cluster_print <- cli::ansi_strip(paste(capture.output(print(cluster)), collapse = "\n"))

  expect_true(grepl("[3/1-10]", cluster_print, fixed = TRUE))
  expect_false(grepl("[5/1-10]", cluster_print, fixed = TRUE))
})

test_that("cluster print does not append Photon when runtime version is unset", {
  cluster <- structure(
    list(
      cluster_id = "c-1",
      cluster_name = "cluster-runtime-missing",
      state = "RUNNING",
      node_type_id = "m5d.large",
      runtime_engine = "PHOTON"
    ),
    class = c("db_cluster", "list")
  )

  cluster_print <- cli::ansi_strip(paste(capture.output(print(cluster)), collapse = "\n"))

  expect_true(grepl("Runtime: <unset>", cluster_print, fixed = TRUE))
  expect_false(grepl("Runtime: <unset> Photon", cluster_print, fixed = TRUE))
})
