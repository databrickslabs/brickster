test_that("SQL Connector Helpers", {

  withr::local_envvar(c(
    "DATABRICKS_HOST" = "mock_host",
    "DATABRICKS_TOKEN" = "mock_token"
  ))

  expect_no_error({
    warehouse_path <- generate_http_path(
      id = "123",
      is_warehouse = TRUE,
      workspace_id = "456"
    )
  })

  expect_no_error({
    cluster_path <- generate_http_path(
      id = "123",
      is_warehouse = TRUE,
      workspace_id = "456"
    )
  })


})

skip_on_cran()
skip_unless_authenticated()
skip_unless_aws_workspace()
skip_without_venv(env = "r-brickster")

test_that("SQL Connector", {

  # create a small serverless sql warehouse to issue queries against
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
    client <- db_sql_client(
      id = test_warehouse$id,
      workspace_id = db_current_workspace_id()
    )
  })

  expect_no_error({
    res1 <- client$execute(operation = "select 1")
  })
  expect_s3_class(res1, "tbl_df")
  expect_identical(res1, tibble::tibble(`1` = 1L))

  expect_no_error({
    catalogs <- client$catalogs()
  })
  expect_s3_class(catalogs, "tbl_df")

  expect_no_error({
    schemas <- client$schemas(catalog_name = "main")
  })
  expect_s3_class(catalogs, "tbl_df")
  expect_identical(unique(schemas$TABLE_CATALOG)[1], "main")

  expect_no_error({
    tables <- client$tables(
      catalog_name = "main",
      schema_name = "information_schema"
    )
  })
  expect_s3_class(tables, "tbl_df")

  expect_no_error({
    columns <- client$columns(
      catalog_name = "samples",
      schema_name = "nyctaxi",
      table_name = "trips"
    )
  })
  expect_s3_class(columns, "tbl_df")

  # cleanup/delete the warehouse used for testing
  expect_no_error({
    db_sql_warehouse_delete(
      id = test_warehouse$id
    )
  })


})
