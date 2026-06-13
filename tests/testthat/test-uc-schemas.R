test_that("Unity Catalog: Schemas API - don't perform", {
  withr::local_envvar(c(
    "DATABRICKS_HOST" = "http://mock_host",
    "DATABRICKS_TOKEN" = "mock_token"
  ))

  resp_schema_list <- db_uc_schemas_list(
    catalog = "some_catalog",
    max_results = 50,
    page_token = "abc",
    perform_request = FALSE
  )
  expect_s3_class(resp_schema_list, "httr2_request")
  query <- httr2::url_parse(resp_schema_list$url)$query
  expect_identical(query$catalog_name, "some_catalog")
  expect_identical(query$max_results, "50")
  expect_identical(query$page_token, "abc")

  resp_schema_get <- db_uc_schemas_get(
    catalog = "some_catalog",
    schema = "some_schema",
    perform_request = FALSE
  )
  expect_s3_class(resp_schema_get, "httr2_request")
})

skip_on_cran()
skip_unless_authenticated()
skip_unless_aws_workspace()

test_that("Unity Catalog: Schemas API", {
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
