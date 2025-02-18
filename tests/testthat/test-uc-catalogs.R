test_that("Unity Catalog: Catalogs API - don't perform", {

  withr::local_envvar(c(
    "DATABRICKS_HOST" = "http://mock_host",
    "DATABRICKS_TOKEN" = "mock_token"
  ))

  resp_catalog_list <- db_uc_catalogs_list(perform_request = F)
  expect_s3_class(resp_catalog_list, "httr2_request")

  resp_catalog_get <- db_uc_catalogs_get(
    catalog = "some_catalog",
    perform_request = F
  )
  expect_s3_class(resp_catalog_get, "httr2_request")

})

skip_on_cran()
skip_unless_authenticated()
skip_unless_aws_workspace()

test_that("Unity Catalog: Catalogs API", {

  expect_no_error({
    resp_catalog_list <- db_uc_catalogs_list()
  })
  expect_type(resp_catalog_list, "list")

  expect_no_error({
    resp_catalog_get <- db_uc_catalogs_get(
      catalog = resp_catalog_list[[1]]$name
    )
  })

})
