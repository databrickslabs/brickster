test_that("Unity Catalog API - don't perform", {

  withr::local_envvar(c(
    "DATABRICKS_HOST" = "http://mock_host",
    "DATABRICKS_TOKEN" = "mock_token"
  ))

  resp_table_summaries <- db_uc_tables_summaries(
    catalog = "some_catalog",
    max_results = 10,
    perform_request = F
  )
  expect_s3_class(resp_table_summaries, "httr2_request")

  resp_tables_list <- db_uc_tables_list(
    catalog = "some_catalog",
    schema = "some_schema",
    perform_request = F
  )
  expect_s3_class(resp_tables_list, "httr2_request")

  resp_table_get <- db_uc_tables_get(
    catalog = "some_catalog",
    schema = "some_schema",
    table = "some_table",
    perform_request = F
  )
  expect_s3_class(resp_table_get, "httr2_request")

  resp_table_delete <- db_uc_tables_delete(
    catalog = "some_catalog",
    schema = "some_schema",
    table = "some_table",
    perform_request = F
  )
  expect_s3_class(resp_table_delete, "httr2_request")

  resp_table_exists <- db_uc_tables_exists(
    catalog = "some_catalog",
    schema = "some_schema",
    table = "some_table",
    perform_request = F
  )
  expect_s3_class(resp_table_exists, "httr2_request")

})

skip_on_cran()
skip_unless_authenticated()
skip_unless_aws_workspace()

test_that("Unity Catalog API", {

  expect_no_error({
    resp_table_summaries <- db_uc_tables_summaries(
      catalog = "main",
      max_results = 10
    )
  })
  expect_type(resp_table_summaries, "list")

  table_name <- strsplit(resp_table_summaries[[1]][[1]]$full_name, "\\.")[[1]]
  expect_length(table_name, 3L)

  expect_no_error({
    resp_tables_list <- db_uc_tables_list(
      catalog = "main",
      schema = table_name[2]
    )
  })
  expect_type(resp_tables_list, "list")

  expect_no_error({
    resp_table_get <- db_uc_tables_get(
      catalog = "main",
      schema = table_name[2],
      table = table_name[3]
    )
  })
  expect_type(resp_table_get, "list")

  expect_no_error({
    resp_table_get <- db_uc_tables_exists(
      catalog = "main",
      schema = table_name[2],
      table = table_name[3]
    )
  })
  expect_type(resp_table_get, "list")

})
