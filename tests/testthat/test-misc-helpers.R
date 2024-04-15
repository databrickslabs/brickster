test_that("Misc Helpers - don't perform", {

  resp_wsid <- db_current_workspace_id(perform_request = F)
  expect_s3_class(resp_wsid, "httr2_request")

  resp_user <- db_current_user(perform_request = F)
  expect_s3_class(resp_user, "httr2_request")

})

skip_unless_authenticated()
skip_unless_aws_workspace()

test_that("Misc Helpers", {

  expect_no_error({
    resp_wsid <- db_current_workspace_id()
  })
  expect_type(resp_wsid, "character")

  expect_no_error({
    resp_user <- db_current_user()
  })
  expect_type(resp_user, "list")

  expect_no_error({
    resp_cloud <- db_current_cloud()
  })
  expect_type(resp_cloud, "character")
  expect_identical(resp_cloud, "aws")

})
