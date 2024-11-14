test_that("Libraries API - don't perform", {

  withr::local_envvar(c(
    "DATABRICKS_HOST" = "mock_host",
    "DATABRICKS_TOKEN" = "mock_token"
  ))

  resp_all_statuses <- db_libs_all_cluster_statuses(
    perform_request = F
  )
  expect_s3_class(resp_all_statuses, "httr2_request")

  expect_error({
    db_libs_install(
      cluster_id = "some_cluster_id",
      libraries = "pandas",
      perform_request = F
    )
  })
  resp_lib_install <- db_libs_install(
    cluster_id = "some_cluster_id",
    libraries = libraries(
      lib_pypi("pandas")
    ),
    perform_request = F
  )
  expect_s3_class(resp_lib_install, "httr2_request")


  resp_lib_status <- db_libs_cluster_status(
    cluster_id = "some_cluster_id",
    perform_request = F
  )
  expect_s3_class(resp_lib_status, "httr2_request")


  expect_error({
    db_libs_uninstall(
      cluster_id = "some_cluster_id",
      libraries = "pandas",
      perform_request = F
    )
  })
  resp_lib_uninstall <- db_libs_uninstall(
    cluster_id = "some_cluster_id",
    libraries = libraries(
      lib_pypi("pandas")
    ),
    perform_request = F
  )
  expect_s3_class(resp_lib_status, "httr2_request")


})

skip_on_cran()
skip_unless_authenticated()
skip_unless_aws_workspace()

test_that("Libraries API", {

  expect_no_error({
    resp_all_statuses <- db_libs_all_cluster_statuses()
  })
  expect_type(resp_all_statuses, "list")

  # create a cluster to install libraries on
  # (AWS specific)
  resp_list_dbrv <- db_cluster_runtime_versions()
  resp_create_cluster <- db_cluster_create(
    name = "brickster_test_libraries_cluster",
    spark_version = resp_list_dbrv[[1]][[1]]$key,
    num_workers = 2,
    node_type_id = "m5a.xlarge",
    cloud_attrs = aws_attributes(
      ebs_volume_size = 32
    ),
    autotermination_minutes = 15
  )

  expect_no_error({
    resp_lib_install <- db_libs_install(
      cluster_id = resp_create_cluster$cluster_id,
      libraries = libraries(
        lib_pypi("pandas")
      )
    )
  })
  expect_type(resp_lib_install, "list")

  expect_no_error({
    resp_lib_status <- db_libs_cluster_status(
      cluster_id = resp_create_cluster$cluster_id
    )
  })
  expect_type(resp_lib_status, "list")
  expect_true(
    resp_lib_status$library_statuses[[1]]$library$pypi$package[1] == "pandas"
  )

  expect_no_error({
    resp_lib_uninstall <- db_libs_uninstall(
      cluster_id = resp_create_cluster$cluster_id,
      libraries = libraries(
        lib_pypi("pandas")
      )
    )
  })

  db_cluster_perm_delete(cluster_id = resp_create_cluster$cluster_id)


})

