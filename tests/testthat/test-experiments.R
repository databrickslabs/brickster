test_that("experiments API - don't perform", {

  withr::local_envvar(c(
    "DATABRICKS_HOST" = "http://mock_host",
    "DATABRICKS_TOKEN" = "mock_token"
  ))

  resp_list <- db_experiments_list(
    max_results = 1,
    page_token = "abc",
    perform_request = FALSE
  )
  expect_s3_class(resp_list, "httr2_request")
  expect_identical(resp_list$body$data$page_token, "abc")

  resp_get_by_name <- db_experiments_get(
    name = "some name",
    perform_request = FALSE
  )
  expect_s3_class(resp_get_by_name, "httr2_request")

  resp_get_by_id <- db_experiments_get(
    id = "some id",
    perform_request = FALSE
  )
  expect_s3_class(resp_get_by_id, "httr2_request")


})

test_that("experiments API preserves pagination response metadata", {
  withr::local_envvar(c(
    "DATABRICKS_HOST" = "http://mock_host",
    "DATABRICKS_TOKEN" = "mock_token"
  ))

  local_mocked_bindings(
    db_perform_request = function(req, ...) {
      list(
        experiments = list(list(name = "some_experiment")),
        next_page_token = "next-page"
      )
    }
  )

  resp_list <- db_experiments_list()

  expect_identical(resp_list$experiments[[1]]$name, "some_experiment")
  expect_identical(resp_list$next_page_token, "next-page")
})

skip_on_cran()
skip_unless_authenticated()
skip_unless_aws_workspace()

test_that("experiments API", {

  resp_list <- db_experiments_list(max_results = 1)
  expect_type(resp_list, "list")
  expect_named(resp_list$experiments[[1]])

  resp_get_by_name <- db_experiments_get(name = resp_list$experiments[[1]]$name)
  expect_equal(resp_list$experiments[[1]]$name, resp_get_by_name$name)

  resp_get_by_id <- db_experiments_get(id = resp_list$experiments[[1]]$experiment_id)
  expect_equal(resp_list$experiments[[1]]$experiment_id, resp_get_by_name$experiment_id)

  # don't allow both
  expect_error(db_experiments_get(
    id = resp_list$experiments[[1]]$experiment_id,
    name = resp_list$experiments[[1]]$name
  ))

})
