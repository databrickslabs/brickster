test_that("Feature Store API", {




})


test_that("Feature Store API - don't perform", {

  resp_get_all <- db_repo_get_all("/", perform_request = FALSE)
  expect_s3_class(resp_get_all, "httr2_request")

  resp_create <- db_repo_create(
    url = "some_url",
    provider = "some_provider",
    path = "some_path",
    perform_request = FALSE
  )
  expect_s3_class(resp_create, "httr2_request")

  resp_get <- db_repo_get(
    repo_id = "some_id",
    perform_request = FALSE
  )
  expect_s3_class(resp_get, "httr2_request")

  resp_update <- db_repo_update(
    repo_id = "some_id",
    branch = "some_branch",
    perform_request = FALSE
  )
  expect_s3_class(resp_get, "httr2_request")

  resp_delete <- db_repo_delete(
    repo_id = "some_id",
    perform_request = FALSE
  )
  expect_s3_class(resp_get, "httr2_request")


})
