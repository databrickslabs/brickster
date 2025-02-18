test_that("Unity Catalog API - don't perform", {

  withr::local_envvar(c(
    "DATABRICKS_HOST" = "http://mock_host",
    "DATABRICKS_TOKEN" = "mock_token"
  ))

  resp_schema_list <- db_uc_schemas_list(
    catalog = "some_catalog",
    perform_request = F
  )
  expect_s3_class(resp_schema_list, "httr2_request")

  resp_schema_get <- db_uc_schemas_get(
    catalog = "some_catalog",
    schema = "some_schema",
    perform_request = F
  )
  expect_s3_class(resp_schema_get, "httr2_request")

})

skip_on_cran()
skip_unless_authenticated()
skip_unless_aws_workspace()

test_that("Unity Catalog API", {

  expect_no_error({
    resp_schema_list <- db_uc_schemas_list(
      catalog = "main"
    )
  })
  expect_type(resp_schema_list, "list")

  expect_no_error({
    resp_schema_get <- db_uc_schemas_get(
      catalog = "main",
      schema = resp_schema_list[[1]]$name
    )
  })
  expect_type(resp_schema_get, "list")

})
