test_that("Unity Catalog: Catalogs API - don't perform", {

  withr::local_envvar(c(
    "DATABRICKS_HOST" = "http://mock_host",
    "DATABRICKS_TOKEN" = "mock_token"
  ))

  resp_catalog_list <- db_uc_catalogs_list(
    max_results = 50,
    include_browse = FALSE,
    page_token = "abc",
    perform_request = FALSE
  )
  expect_s3_class(resp_catalog_list, "httr2_request")
  query <- httr2::url_parse(resp_catalog_list$url)$query
  expect_identical(query$max_results, "50")
  expect_identical(query$include_browse, "false")
  expect_identical(query$page_token, "abc")

  resp_catalog_get <- db_uc_catalogs_get(
    catalog = "some_catalog",
    perform_request = FALSE
  )
  expect_s3_class(resp_catalog_get, "httr2_request")

})

test_that("Unity Catalog: Catalogs API preserves pagination response metadata", {
  withr::local_envvar(c(
    "DATABRICKS_HOST" = "http://mock_host",
    "DATABRICKS_TOKEN" = "mock_token"
  ))

  local_mocked_bindings(
    db_perform_request = function(req, ...) {
      list(
        catalogs = list(list(name = "some_catalog")),
        next_page_token = "next-page"
      )
    }
  )

  resp_catalog_list <- db_uc_catalogs_list()

  expect_identical(resp_catalog_list$catalogs[[1]]$name, "some_catalog")
  expect_identical(resp_catalog_list$next_page_token, "next-page")
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
      catalog = resp_catalog_list$catalogs[[1]]$name
    )
  })

})
