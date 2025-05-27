test_that("Queries API - don't perform", {
  withr::local_envvar(c(
    "DATABRICKS_HOST" = "http://mock_host",
    "DATABRICKS_TOKEN" = "mock_token"
  ))

  resp_list <- db_query_list(perform_request = FALSE)
  expect_s3_class(resp_list, "httr2_request")

  resp_get <- db_query_get(id = "some_id", perform_request = FALSE)
  expect_s3_class(resp_get, "httr2_request")

  resp_delete <- db_query_delete(id = "some_id", perform_request = FALSE)
  expect_s3_class(resp_delete, "httr2_request")

  resp_create <- db_query_create(
    warehouse_id = "some_id",
    query_text = "select 1",
    display_name = "some_name",
    perform_request = FALSE
  )
  expect_s3_class(resp_create, "httr2_request")

  resp_update <- db_query_update(
    id = "some_id",
    query_text = "select 2",
    perform_request = FALSE
  )
  expect_s3_class(resp_update, "httr2_request")
})

skip_on_cran()
skip_unless_authenticated()
skip_unless_aws_workspace()

test_that("Queries API", {
  # create a small serverless sql warehouse to create query
  expect_no_error({
    random_id <- sample.int(100000, 1)
    test_warehouse <- db_sql_warehouse_create(
      name = paste0("brickster_test_warehouse_", random_id),
      cluster_size = "2X-Small",
      warehouse_type = "PRO",
      enable_serverless_compute = TRUE
    )
  })

  expect_no_error({
    db_query_list()
  })

  expect_no_error({
    query <- db_query_create(
      warehouse_id = test_warehouse$id,
      query_text = "select 1",
      display_name = "brickster_query"
    )
  })

  expect_no_error({
    query_updated <- db_query_update(
      id = query$id,
      query_text = "select 2",
      display_name = "brickster_query_updated"
    )
  })

  expect_no_error({
    query_deleted <- db_query_delete(id = query$id)
  })
  expect_length(query_deleted, 0L)

  # check state of query - should be trashed
  expect_no_error({
    query_del_get <- db_query_get(id = query_updated$id)
  })
  expect_equal(query_del_get$lifecycle_state, "TRASHED")

  # cleanup/delete the warehouse used for testing
  expect_no_error({
    db_sql_warehouse_delete(
      id = test_warehouse$id
    )
  })
})
