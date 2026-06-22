test_that("Unity Catalog: Tables API - don't perform", {

  withr::local_envvar(c(
    "DATABRICKS_HOST" = "http://mock_host",
    "DATABRICKS_TOKEN" = "mock_token"
  ))

  resp_table_summaries <- db_uc_tables_summaries(
    catalog = "some_catalog",
    max_results = 10,
    perform_request = FALSE
  )
  expect_s3_class(resp_table_summaries, "httr2_request")

  resp_tables_list <- db_uc_tables_list(
    catalog = "some_catalog",
    schema = "some_schema",
    max_results = 10,
    page_token = "abc",
    perform_request = FALSE
  )
  expect_s3_class(resp_tables_list, "httr2_request")
  query <- httr2::url_parse(resp_tables_list$url)$query
  expect_identical(query$catalog_name, "some_catalog")
  expect_identical(query$schema_name, "some_schema")
  expect_identical(query$max_results, "10")
  expect_identical(query$page_token, "abc")

  resp_table_get <- db_uc_tables_get(
    catalog = "some_catalog",
    schema = "some_schema",
    table = "some_table",
    perform_request = FALSE
  )
  expect_s3_class(resp_table_get, "httr2_request")

  resp_table_delete <- db_uc_tables_delete(
    catalog = "some_catalog",
    schema = "some_schema",
    table = "some_table",
    perform_request = FALSE
  )
  expect_s3_class(resp_table_delete, "httr2_request")

  resp_table_exists <- db_uc_tables_exists(
    catalog = "some_catalog",
    schema = "some_schema",
    table = "some_table",
    perform_request = FALSE
  )
  expect_s3_class(resp_table_exists, "httr2_request")

})

test_that("Unity Catalog: Tables API preserves pagination response metadata", {
  withr::local_envvar(c(
    "DATABRICKS_HOST" = "http://mock_host",
    "DATABRICKS_TOKEN" = "mock_token"
  ))

  local_mocked_bindings(
    db_perform_request = function(req, ...) {
      list(
        tables = list(list(name = "some_table")),
        next_page_token = "next-page"
      )
    }
  )

  resp_tables_list <- db_uc_tables_list(
    catalog = "some_catalog",
    schema = "some_schema"
  )

  expect_identical(resp_tables_list$tables[[1]]$name, "some_table")
  expect_identical(resp_tables_list$next_page_token, "next-page")
})

skip_on_cran()
skip_unless_authenticated()
skip_unless_aws_workspace()

test_that("Unity Catalog: Tables API", {

  expect_no_error({
    resp_table_summaries <- db_uc_tables_summaries(
      catalog = "main",
      max_results = 10
    )
  })
  expect_type(resp_table_summaries, "list")

  table_name <- strsplit(resp_table_summaries[[1]][[1]]$full_name, ".", fixed = TRUE)[[1]]
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
