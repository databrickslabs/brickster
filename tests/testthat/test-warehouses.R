skip_unless_credentials_set()

test_that("Warehouse API - don't perform", {

  resp_list <- db_sql_warehouse_list(perform_request = F)
  expect_s3_class(resp_list, "httr2_request")

  resp_global_get <- db_sql_global_warehouse_get(perform_request = F)
  expect_s3_class(resp_global_get, "httr2_request")

  resp_create <- db_sql_warehouse_create(
    name = "brickster_test_warehouse",
    cluster_size = "2X-Small",
    enable_serverless_compute = TRUE,
    perform_request = F
  )
  expect_s3_class(resp_create, "httr2_request")

  resp_get <- db_sql_warehouse_get(
    id = "some_warehouse_id",
    perform_request = F
  )
  expect_s3_class(resp_get, "httr2_request")

  resp_stop <- db_sql_warehouse_stop(
    id = "some_warehouse_id",
    perform_request = F
  )
  expect_s3_class(resp_stop, "httr2_request")

  resp_edit <- db_sql_warehouse_edit(
    id = "some_warehouse_id",
    name = "some_warehouse_name",
    cluster_size =  "2X-Small",
    spot_instance_policy = "COST_OPTIMIZED",
    channel = "CHANNEL_NAME_CURRENT",
    warehouse_type = "PRO",
    perform_request = F
  )
  expect_s3_class(resp_edit, "httr2_request")

  resp_start <- db_sql_warehouse_start(
    id = "some_warehouse_id",
    perform_request = F
  )
  expect_s3_class(resp_start, "httr2_request")

  resp_delete <- db_sql_warehouse_delete(
    id = "some_warehouse_id",
    perform_request = F
  )
  expect_s3_class(resp_delete, "httr2_request")

})

skip_on_cran()
skip_unless_authenticated()
skip_unless_aws_workspace()

test_that("Warehouse API", {

  expect_no_error({
    resp_list <- db_sql_warehouse_list()
  })
  expect_type(resp_list, "list")

  expect_no_error({
    resp_global_get <- db_sql_global_warehouse_get()
  })
  expect_type(resp_global_get, "list")

  expect_no_error({
    resp_create <- db_sql_warehouse_create(
      name = "brickster_test_warehouse",
      cluster_size = "2X-Small",
      warehouse_type = "PRO",
      enable_serverless_compute = TRUE
    )
  })
  expect_type(resp_create, "list")

  expect_no_error({
    resp_get <- db_sql_warehouse_get(
      id = resp_create$id
    )
  })
  expect_type(resp_get, "list")

  expect_no_error({
    resp_stop <- db_sql_warehouse_stop(
      id = resp_create$id
    )
  })
  expect_type(resp_stop, "list")
  expect_length(resp_stop, 0L)

  expect_no_error({
    resp_edit <- db_sql_warehouse_edit(
      id = resp_create$id,
      name = "brickster_test_warehouse_renamed",
      cluster_size =  "2X-Small",
      spot_instance_policy = "COST_OPTIMIZED",
      enable_serverless_compute = TRUE,
      channel = "CHANNEL_NAME_CURRENT",
      warehouse_type = "PRO"
    )
  })
  expect_type(resp_edit, "list")
  expect_length(resp_edit, 0L)

  expect_no_error({
    resp_start <- db_sql_warehouse_start(
      id = resp_create$id
    )
  })
  expect_type(resp_start, "list")
  expect_length(resp_start, 0L)

  expect_no_error({
    resp_stop <- db_sql_warehouse_stop(
      id = resp_create$id
    )
    resp_get_start <- get_and_start_warehouse(
      id = resp_create$id
    )
  })
  expect_type(resp_get_start, "list")

  expect_no_error({
    resp_delete <- db_sql_warehouse_delete(
      id = resp_create$id
    )
  })
  expect_type(resp_delete, "list")
  expect_length(resp_delete, 0L)

})
