test_that("Clusters API - don't perform", {
  withr::local_envvar(c(
    "DATABRICKS_HOST" = "http://mock_host",
    "DATABRICKS_TOKEN" = "mock_token"
  ))

  # basic metadata functions
  resp_list <- db_cluster_list(perform_request = F)
  expect_s3_class(resp_list, "httr2_request")

  resp_list_zones <- db_cluster_list_zones(perform_request = F)
  expect_s3_class(resp_list_zones, "httr2_request")

  resp_list_ntypes <- db_cluster_list_node_types(perform_request = F)
  expect_s3_class(resp_list_ntypes, "httr2_request")

  resp_list_dbrv <- db_cluster_runtime_versions(perform_request = F)
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
    perform_request = F
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
    perform_request = F
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
    perform_request = F
  )
  expect_s3_class(resp_create, "httr2_request")

  resp_get <- db_cluster_get(resp_create$cluster_id, perform_request = F)
  expect_s3_class(resp_get, "httr2_request")

  resp_pin <- db_cluster_pin(resp_create$cluster_id, perform_request = F)
  expect_s3_class(resp_pin, "httr2_request")

  resp_unpin <- db_cluster_unpin(resp_create$cluster_id, perform_request = F)
  expect_s3_class(resp_unpin, "httr2_request")

  resp_events <- db_cluster_events(resp_create$cluster_id, perform_request = F)
  expect_s3_class(resp_events, "httr2_request")

  resp_resize <- db_cluster_resize(
    cluster_id = resp_create$cluster_id,
    num_workers = 4,
    perform_request = F
  )
  expect_s3_class(resp_resize, "httr2_request")

  resp_resize <- db_cluster_resize(
    cluster_id = resp_create$cluster_id,
    autoscale = cluster_autoscale(2, 4),
    perform_request = F
  )
  expect_s3_class(resp_resize, "httr2_request")

  resp_terminate <- db_cluster_terminate(
    cluster_id = resp_create$cluster_id,
    perform_request = F
  )
  expect_s3_class(resp_terminate, "httr2_request")

  resp_delete <- db_cluster_delete(
    cluster_id = resp_create$cluster_id,
    perform_request = F
  )
  expect_s3_class(resp_delete, "httr2_request")

  resp_restart <- db_cluster_restart(
    cluster_id = resp_create$cluster_id,
    perform_request = F
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
    perform_request = F
  )
  expect_s3_class(resp_edit, "httr2_request")

  resp_delete <- db_cluster_perm_delete(
    cluster_id = resp_create$cluster_id,
    perform_request = F
  )
  expect_s3_class(resp_delete, "httr2_request")
})

skip_on_cran()
skip_unless_authenticated()
skip_unless_aws_workspace()

test_that("Clusters API", {
  # basic metadata functions
  expect_no_error({
    resp_list <- db_cluster_list()
  })
  expect_type(resp_list, "list")

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
  std_runtimes <- purrr::keep(runtimes, ~ !grepl("photon|gpu", .x))

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
    resp_events <- db_cluster_events(resp_create$cluster_id)
  })

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
