test_that("Workspace API - don't perform", {

  withr::local_envvar(c(
    "DATABRICKS_HOST" = "http://mock_host",
    "DATABRICKS_TOKEN" = "mock_token"
  ))

  resp_list <- db_workspace_list(
    path = "some_path",
    perform_request = F
  )
  expect_s3_class(resp_list, "httr2_request")

  resp_mkdirs <- db_workspace_mkdirs(
    path = "some_path",
    perform_request = F
  )
  expect_s3_class(resp_mkdirs, "httr2_request")

  resp_get_status <- db_workspace_get_status(
    path = "some_path",
    perform_request = F
  )
  expect_s3_class(resp_get_status, "httr2_request")

  resp_delete <- db_workspace_delete(
    path = "some_path",
    perform_request = F
  )
  expect_s3_class(resp_delete, "httr2_request")

  resp_export <- db_workspace_export(
    path = "some_path",
    perform_request = F
  )
  expect_s3_class(resp_export, "httr2_request")

  resp_import <- db_workspace_import(
    path = "some_path",
    content = "some_content",
    language = "PYTHON",
    perform_request = F
  )
  expect_s3_class(resp_import, "httr2_request")

  expect_error({
    db_workspace_import(
      path = "some_path",
      file = "some_file",
      language = "some_langauge", # must be a valid language
      perform_request = F
    )
  })

  # must specify either `file` or `content`
  expect_error({
    db_workspace_import(
      path = "some_path",
      file = NULL,
      content = NULL,
      language = "PYTHON",
      perform_request = F
    )
  })

})

skip_on_cran()
skip_unless_authenticated()
skip_unless_aws_workspace()

test_that("Workspace API", {

  expect_no_error({
    resp_list <- db_workspace_list(path = "/Shared/")
  })
  expect_type(resp_list, "list")

  expect_no_error({
    resp_mkdirs <- db_workspace_mkdirs(path = "/Shared/brickster_dir_test/")
  })
  expect_null(resp_mkdirs)

  expect_no_error({
    resp_get_status <- db_workspace_get_status(
      path = "/Shared/brickster_dir_test/"
    )
  })
  expect_type(resp_get_status, "list")
  expect_identical(resp_get_status$object_type, "DIRECTORY")
  expect_identical(resp_get_status$path, "/Shared/brickster_dir_test")

  expect_no_error({
    resp_delete <- db_workspace_delete(
      path = "/Shared/brickster_dir_test/"
    )
  })
  expect_type(resp_delete, "list")

})
