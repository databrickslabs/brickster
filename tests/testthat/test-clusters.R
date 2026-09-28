test_that("Clusters API - don't perform", {
  withr::local_envvar(c(
    "DATABRICKS_HOST" = "http://mock_host",
    "DATABRICKS_TOKEN" = "mock_token"
  ))

  # basic metadata functions
  resp_list <- db_cluster_list(perform_request = FALSE)
  expect_s3_class(resp_list, "httr2_request")

  resp_list_zones <- db_cluster_list_zones(perform_request = FALSE)
  expect_s3_class(resp_list_zones, "httr2_request")

  resp_list_ntypes <- db_cluster_list_node_types(perform_request = FALSE)
  expect_s3_class(resp_list_ntypes, "httr2_request")

  resp_list_dbrv <- db_cluster_runtime_versions(perform_request = FALSE)
  expect_s3_class(resp_list_dbrv, "httr2_request")

  # creating cluster (AWS specific)
  resp_create <- db_cluster_create(
    name = "brickster_test_cluster",
    spark_version = "some_runtime_string",
    num_workers = 2,
    node_type_id = "some_node_type",
    cloud_attrs = aws_attributes(
      ebs_volume_size = 32
    ),
    autotermination_minutes = 15,
    perform_request = FALSE
  )
  expect_s3_class(resp_create, "httr2_request")

  # creating cluster (Azure specific)
  resp_create <- db_cluster_create(
    name = "brickster_test_cluster",
    spark_version = "some_runtime_string",
    num_workers = 2,
    node_type_id = "some_node_type",
    cloud_attrs = azure_attributes(),
    autotermination_minutes = 15,
    perform_request = FALSE
  )
  expect_s3_class(resp_create, "httr2_request")

  # creating cluster (GCP specific)
  resp_create <- db_cluster_create(
    name = "brickster_test_cluster",
    spark_version = "some_runtime_string",
    autoscale = cluster_autoscale(2, 4),
    node_type_id = "some_node_type",
    cloud_attrs = gcp_attributes(),
    autotermination_minutes = 15,
    perform_request = FALSE
  )
  expect_s3_class(resp_create, "httr2_request")

  resp_get <- db_cluster_get(resp_create$cluster_id, perform_request = FALSE)
  expect_s3_class(resp_get, "httr2_request")

  resp_pin <- db_cluster_pin(resp_create$cluster_id, perform_request = FALSE)
  expect_s3_class(resp_pin, "httr2_request")

  resp_unpin <- db_cluster_unpin(resp_create$cluster_id, perform_request = FALSE)
  expect_s3_class(resp_unpin, "httr2_request")

  resp_events <- db_cluster_events(resp_create$cluster_id, perform_request = FALSE)
  expect_s3_class(resp_events, "httr2_request")

  resp_resize <- db_cluster_resize(
    cluster_id = resp_create$cluster_id,
    num_workers = 4,
    perform_request = FALSE
  )
  expect_s3_class(resp_resize, "httr2_request")

  resp_resize <- db_cluster_resize(
    cluster_id = resp_create$cluster_id,
    autoscale = cluster_autoscale(2, 4),
    perform_request = FALSE
  )
  expect_s3_class(resp_resize, "httr2_request")

  resp_terminate <- db_cluster_terminate(
    cluster_id = resp_create$cluster_id,
    perform_request = FALSE
  )
  expect_s3_class(resp_terminate, "httr2_request")

  resp_delete <- db_cluster_delete(
    cluster_id = resp_create$cluster_id,
    perform_request = FALSE
  )
  expect_s3_class(resp_delete, "httr2_request")

  resp_restart <- db_cluster_restart(
    cluster_id = resp_create$cluster_id,
    perform_request = FALSE
  )
  expect_s3_class(resp_restart, "httr2_request")

  resp_edit <- db_cluster_edit(
    cluster_id = resp_create$cluster_id,
    name = "brickster_test_cluster_renamed",
    spark_version = "some_spark_version",
    node_type_id = "m5a.xlarge",
    num_workers = 2,
    cloud_attrs = aws_attributes(
      ebs_volume_size = 32
    ),
    perform_request = FALSE
  )
  expect_s3_class(resp_edit, "httr2_request")

  resp_delete <- db_cluster_perm_delete(
    cluster_id = resp_create$cluster_id,
    perform_request = FALSE
  )
  expect_s3_class(resp_delete, "httr2_request")
})

test_that("cluster wrappers use the Clusters API 2.1 paths and methods", {
  withr::local_envvar(c(DATABRICKS_HOST = "mock_host", DATABRICKS_TOKEN = "mock_token"))
  requests <- list(
    create = db_cluster_create("test", "runtime", "node", num_workers = 1, perform_request = FALSE),
    edit = db_cluster_edit("c-1", "runtime", "node", perform_request = FALSE),
    start = db_cluster_start("c-1", perform_request = FALSE),
    restart = db_cluster_restart("c-1", perform_request = FALSE),
    delete = db_cluster_delete("c-1", perform_request = FALSE),
    delete = db_cluster_terminate("c-1", perform_request = FALSE),
    `permanent-delete` = db_cluster_perm_delete("c-1", perform_request = FALSE),
    pin = db_cluster_pin("c-1", perform_request = FALSE),
    unpin = db_cluster_unpin("c-1", perform_request = FALSE),
    resize = db_cluster_resize("c-1", num_workers = 2, perform_request = FALSE),
    get = db_cluster_get("c-1", perform_request = FALSE),
    list = db_cluster_list(perform_request = FALSE),
    `list-node-types` = db_cluster_list_node_types(perform_request = FALSE),
    `spark-versions` = db_cluster_runtime_versions(perform_request = FALSE),
    `list-zones` = db_cluster_list_zones(perform_request = FALSE),
    events = db_cluster_events("c-1", perform_request = FALSE)
  )
  get_endpoints <- c("get", "list", "list-node-types", "spark-versions", "list-zones")
  purrr::iwalk(requests, function(req, endpoint) {
    expect_s3_class(req, "httr2_request")
    expect_identical(httr2::url_parse(req$url)$path, paste0("/api/2.1/clusters/", endpoint))
    expect_identical(req$method, if (endpoint %in% get_endpoints) "GET" else "POST")
  })
  expect_identical(httr2::url_parse(requests$get$url)$query$cluster_id, "c-1")
  expect_null(requests$get$body)
})

test_that("cluster listing sends pagination as query parameters", {
  req <- db_cluster_list("mock_host", "mock_token", FALSE, page_size = 100, page_token = "next+/=")
  expect_identical(httr2::url_parse(req$url)$query, list(page_size = "100", page_token = "next+/="))
  expect_null(req$body)
  req <- db_cluster_list("mock_host", "mock_token", FALSE)
  expect_identical(httr2::url_parse(req$url)$query, list(page_size = "20"))
  req <- db_cluster_list("mock_host", "mock_token", FALSE, page_size = NULL)
  expect_length(httr2::url_parse(req$url)$query, 0)
})

test_that("cluster event requests retain timestamps and use token pagination", {
  withr::local_envvar(c(DATABRICKS_HOST = "mock_host", DATABRICKS_TOKEN = "mock_token"))
  req <- db_cluster_events(
    "c-1", start_time = 1790553600000, end_time = 1790640000000,
    event_types = list("RUNNING", "TERMINATING"), order = "ASC",
    page_size = 500, page_token = "next+/=", perform_request = FALSE
  )
  body <- jsonlite::fromJSON(db_request_json(req))
  expect_identical(body$start_time, 1790553600000)
  expect_identical(body$end_time, 1790640000000)
  expect_identical(body$event_types, c("RUNNING", "TERMINATING"))
  expect_identical(body$order, "ASC")
  expect_identical(body$page_size, 500L)
  expect_identical(body$page_token, "next+/=")
  expect_null(body$offset)
  expect_null(body$limit)

  default <- db_cluster_events("c-1", perform_request = FALSE)$body$data
  expect_identical(default, list(cluster_id = "c-1", order = "DESC", page_size = 50))
  zero <- db_cluster_events("c-1", page_size = 0, perform_request = FALSE)$body$data
  expect_identical(zero$page_size, 0)
  omitted <- db_cluster_events("c-1", page_size = NULL, perform_request = FALSE)$body$data
  expect_null(omitted$page_size)
})

test_that("legacy event pagination warns and preserves positional arguments", {
  withr::local_options(lifecycle_verbosity = "warning")
  expect_warning(
    req <- db_cluster_events(
      "c-1", NULL, 1790640000000, NULL, "DESC", 25, NULL,
      "mock_host", "mock_token", FALSE
    ),
    "offset.*deprecated", class = "lifecycle_warning_deprecated"
  )
  expect_identical(req$body$data$offset, 25)
  expect_null(req$body$data$page_size)
  expect_null(req$body$data$page_token)
  expect_warning(
    req <- db_cluster_events(
      "c-1", limit = 100, host = "mock_host", token = "mock_token", perform_request = FALSE
    ),
    "limit.*deprecated", class = "lifecycle_warning_deprecated"
  )
  expect_identical(req$body$data$limit, 100)
  expect_null(req$body$data$page_size)
})

test_that("pagination and timestamp validation fails before authentication", {
  invalid_sizes <- list(-1, 101, 1.5, NA_real_, Inf, "20", numeric(), c(1, 2), TRUE)
  purrr::walk(invalid_sizes, function(value) {
    expect_error(db_cluster_list(page_size = value, perform_request = FALSE), "page_size")
  })
  purrr::walk(list(-1, 501, 1.5, NA_real_, Inf, "20", numeric(), c(1, 2)), function(value) {
    expect_error(db_cluster_events("c-1", page_size = value, perform_request = FALSE), "page_size")
  })
  purrr::walk(list(1, NA_character_, character(), c("a", "b")), function(value) {
    expect_error(db_cluster_list(page_token = value, perform_request = FALSE), "page_token")
    expect_error(db_cluster_events("c-1", page_token = value, perform_request = FALSE), "page_token")
  })
  purrr::walk(c("offset", "limit", "start_time", "end_time"), function(arg) {
    purrr::walk(list(-1, NA_real_, Inf, "100", c(1, 2), 1.5), function(value) {
      args <- c(list(cluster_id = "c-1", perform_request = FALSE), setNames(list(value), arg))
      expect_error(do.call(db_cluster_events, args), arg)
    })
  })
  expect_error(db_cluster_events("c-1", start_time = 20, end_time = 10), "start_time.*end_time")
  expect_error(db_cluster_events("c-1", offset = 0, page_token = "next"), "not both")
  expect_error(db_cluster_events("c-1", limit = 50, page_size = 100), "not both")
})

skip_on_cran()
skip_unless_authenticated()
skip_unless_aws_workspace()

test_that("Clusters API", {
  # basic metadata functions
  expect_no_error({
    resp_list <- db_cluster_list(page_size = 1)
  })
  expect_s3_class(resp_list, "db_cluster_list")
  expect_lte(length(resp_list$clusters), 1L)
  if (!is.null(resp_list$next_page_token) && nzchar(resp_list$next_page_token)) {
    next_page <- db_cluster_list(page_size = 1, page_token = resp_list$next_page_token)
    expect_s3_class(next_page, "db_cluster_list")
    expect_lte(length(next_page$clusters), 1L)
  }

  expect_no_error({
    resp_list_zones <- db_cluster_list_zones()
  })
  expect_type(resp_list_zones, "list")

  expect_no_error({
    resp_list_ntypes <- db_cluster_list_node_types()
  })
  expect_type(resp_list_ntypes, "list")

  expect_no_error({
    resp_list_dbrv <- db_cluster_runtime_versions()
  })
  expect_type(resp_list_dbrv, "list")

  # creating cluster (AWS specific)
  # use a standard runtime
  runtimes <- sort(
    purrr::map_chr(resp_list_dbrv$versions, "key"),
    decreasing = TRUE
  )
  std_runtimes <- purrr::keep(runtimes, \(x) !grepl("photon|gpu", x))

  expect_no_error({
    resp_create <- db_cluster_create(
      name = "brickster_test_cluster",
      spark_version = std_runtimes[1],
      num_workers = 2,
      node_type_id = "m7a.xlarge",
      cloud_attrs = aws_attributes(
        ebs_volume_size = 32
      ),
      autotermination_minutes = 15,
      data_security_mode = "DATA_SECURITY_MODE_AUTO"
    )
  })

  expect_no_error({
    resp_get <- db_cluster_get(resp_create$cluster_id)
  })

  # test env currently has max number of pins
  # resp_pin <- db_cluster_pin(resp_create$cluster_id)

  expect_no_error({
    resp_unpin <- db_cluster_unpin(resp_create$cluster_id)
  })

  expect_no_error({
    resp_events <- db_cluster_events(resp_create$cluster_id, page_size = 1)
  })
  expect_type(resp_events, "list")
  expect_lte(length(resp_events$events), 1L)
  if (!is.null(resp_events$next_page_token) && nzchar(resp_events$next_page_token)) {
    next_events <- db_cluster_events(
      resp_create$cluster_id, page_size = 1, page_token = resp_events$next_page_token
    )
    expect_type(next_events, "list")
    expect_lte(length(next_events$events), 1L)
  }

  expect_no_error({
    resp_terminate <- db_cluster_terminate(cluster_id = resp_create$cluster_id)
  })

  expect_no_error({
    resp_perm_delete <- db_cluster_perm_delete(
      cluster_id = resp_create$cluster_id
    )
  })

  expect_no_error({
    dbr1 <- get_latest_dbr(lts = TRUE, ml = FALSE, gpu = FALSE, photon = FALSE)
  })
  expect_type(dbr1, "list")
  expect_length(dbr1, 2)

  expect_no_error({
    dbr2 <- get_latest_dbr(lts = FALSE, ml = FALSE, gpu = FALSE, photon = FALSE)
  })
  expect_type(dbr2, "list")
  expect_length(dbr2, 2)

  expect_no_error({
    dbr3 <- get_latest_dbr(lts = TRUE, ml = TRUE, gpu = FALSE, photon = FALSE)
  })
  expect_type(dbr3, "list")
  expect_length(dbr3, 2)

  expect_no_error({
    dbr4 <- get_latest_dbr(lts = TRUE, ml = TRUE, gpu = TRUE, photon = FALSE)
  })
  expect_type(dbr4, "list")
  expect_length(dbr4, 2)

  expect_no_error({
    dbr5 <- get_latest_dbr(lts = TRUE, ml = FALSE, gpu = FALSE, photon = TRUE)
  })
  expect_type(dbr5, "list")
  expect_length(dbr5, 2)

  expect_error({
    get_latest_dbr(lts = TRUE, ml = TRUE, gpu = TRUE, photon = TRUE)
  })

  expect_error({
    get_latest_dbr(lts = TRUE, ml = TRUE, gpu = FALSE, photon = TRUE)
  })

  expect_error({
    get_latest_dbr(lts = TRUE, ml = FALSE, gpu = TRUE, photon = TRUE)
  })

  expect_error({
    get_latest_dbr(lts = FALSE, ml = FALSE, gpu = TRUE, photon = TRUE)
  })
})
