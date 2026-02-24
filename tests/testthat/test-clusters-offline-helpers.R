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
    perform_request = TRUE
  )

  expect_identical(create_out$cluster_id, "c-1")
  expect_true(!is.null(state$create_body$autoscale))
  expect_true(!is.null(state$create_body$azure_attributes))

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
    perform_request = TRUE
  )

  expect_true(edit_out$ok)
  expect_true(!is.null(state$edit_body$autoscale))
  expect_true(!is.null(state$edit_body$azure_attributes))
})

test_that("cluster action/list wrappers return expected payload shapes", {
  withr::local_envvar(c(
    "DATABRICKS_HOST" = "http://mock_host",
    "DATABRICKS_TOKEN" = "mock_token"
  ))

  req <- structure(list(), class = "httr2_request")

  local_mocked_bindings(
    db_request = function(...) req,
    db_perform_request = function(req) {
      list(
        clusters = list(list(cluster_id = "c-1")),
        node_types = list(list(node_type_id = "m5d.large")),
        versions = list(list(key = "14.3.x-scala2.12")),
        zones = c("us-west-2a"),
        events = list(list(type = "RUNNING"))
      )
    },
    .package = "brickster"
  )
  local_mocked_bindings(
    req_body_json = function(req, body) req,
    req_perform = function(req) structure(list(), class = "httr2_response"),
    resp_body_json = function(resp, ...) list(cluster_id = "c-1", state = "RUNNING"),
    .package = "httr2"
  )

  expect_null(db_cluster_action(cluster_id = "c-1", action = "start", perform_request = TRUE))

  expect_identical(db_cluster_list(perform_request = TRUE)[[1]]$cluster_id, "c-1")
  expect_identical(db_cluster_list_node_types(perform_request = TRUE)$node_types[[1]]$node_type_id, "m5d.large")
  expect_identical(db_cluster_runtime_versions(perform_request = TRUE)$versions[[1]]$key, "14.3.x-scala2.12")
  expect_identical(db_cluster_list_zones(perform_request = TRUE)$zones, "us-west-2a")
  expect_identical(db_cluster_events(cluster_id = "c-1", perform_request = TRUE)[[1]]$type, "RUNNING")
  expect_identical(db_cluster_get(cluster_id = "c-1", perform_request = TRUE)$cluster_id, "c-1")
})

test_that("cluster get/list responses add print classes without changing list access", {
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
      if (identical(req$endpoint, "clusters/list")) {
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

      cli::cli_abort("Unexpected endpoint in test mock: {req$endpoint}")
    },
    db_perform_response = function(req) {
      if (identical(req$endpoint, "clusters/get")) {
        return(structure(
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
          class = "httr2_response"
        ))
      }

      cli::cli_abort("Unexpected endpoint in test mock: {req$endpoint}")
    },
    .package = "brickster"
  )

  local_mocked_bindings(
    resp_body_json = function(resp, ...) unclass(resp),
    .package = "httr2"
  )

  cluster <- db_cluster_get(cluster_id = "c-1", perform_request = TRUE)
  clusters <- db_cluster_list(perform_request = TRUE)

  expect_type(cluster, "list")
  expect_s3_class(cluster, c("db_cluster", "list"))
  expect_identical(cluster$cluster_id, "c-1")

  expect_type(clusters, "list")
  expect_s3_class(clusters, c("db_cluster_list", "list"))
  expect_s3_class(clusters[[1]], c("db_cluster", "list"))
  expect_identical(clusters[[2]]$cluster_id, "c-2")

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
