test_that("Unity Catalog: Volumes API - don't perform", {

  withr::local_envvar(c(
    "DATABRICKS_HOST" = "http://mock_host",
    "DATABRICKS_TOKEN" = "mock_token"
  ))

  resp_volumes_list <- db_uc_volumes_list(
    catalog = "some_catalog",
    schema = "some_schema",
    page_token = "abc",
    perform_request = FALSE
  )
  expect_s3_class(resp_volumes_list, "httr2_request")
  query <- httr2::url_parse(resp_volumes_list$url)$query
  expect_identical(query$catalog_name, "some_catalog")
  expect_identical(query$schema_name, "some_schema")
  expect_identical(query$page_token, "abc")

  resp_volumes_get <- db_uc_volumes_get(
    catalog = "some_catalog",
    schema = "some_schema",
    volume = "some_volume",
    perform_request = FALSE
  )
  expect_s3_class(resp_volumes_get, "httr2_request")

  resp_volumes_delete <- db_uc_volumes_delete(
    catalog = "some_catalog",
    schema = "some_schema",
    volume = "some_volume",
    perform_request = FALSE
  )
  expect_s3_class(resp_volumes_delete, "httr2_request")

  resp_volumes_create <- db_uc_volumes_create(
    catalog = "some_catalog",
    schema = "some_schema",
    volume = "some_volume",
    volume_type = "MANAGED",
    perform_request = FALSE
  )
  expect_s3_class(resp_volumes_create, "httr2_request")
  expect_error({
    db_uc_volumes_create(
      catalog = "some_catalog",
      schema = "some_schema",
      volume = "some_volume",
      volume_type = "MANAGED",
      storage_location = "some_path",
      perform_request = FALSE
    )
  })

  resp_volumes_update <- db_uc_volumes_update(
    catalog = "some_catalog",
    schema = "some_schema",
    volume = "some_volume",
    new_name = "some_new_name",
    perform_request = FALSE
  )
  expect_s3_class(resp_volumes_update, "httr2_request")

})

test_that("Unity Catalog: Volumes API preserves pagination response metadata", {
  withr::local_envvar(c(
    "DATABRICKS_HOST" = "http://mock_host",
    "DATABRICKS_TOKEN" = "mock_token"
  ))

  local_mocked_bindings(
    db_perform_request = function(req, ...) {
      list(
        volumes = list(list(name = "some_volume")),
        next_page_token = "next-page"
      )
    }
  )

  resp_volumes_list <- db_uc_volumes_list(
    catalog = "some_catalog",
    schema = "some_schema"
  )

  expect_identical(resp_volumes_list$volumes[[1]]$name, "some_volume")
  expect_identical(resp_volumes_list$next_page_token, "next-page")
})

skip_on_cran()
skip_unless_authenticated()
skip_unless_aws_workspace()

test_that("Unity Catalog: Volumes API", {

  expect_no_error({
    resp_volumes_list <- db_uc_volumes_list("main", "default")
  })
  expect_type(resp_volumes_list, "list")

  expect_no_error({
    resp_volumes_get <- db_uc_volumes_get(
      catalog = resp_volumes_list$volumes[[1]]$catalog_name,
      schema = resp_volumes_list$volumes[[1]]$schema_name,
      volume = resp_volumes_list$volumes[[1]]$name
    )
  })

  # TODO: consider tests to:
  # 1. create volume
  # 2. get new created volume
  # 3. update new created volume (rename)
  # 4. get volume created in (2) and expect error
  # 5. get volume updated in (3) and expect success
  # 6. delete volume from (3)
  # 7. get volume from (3) and expect error

})
