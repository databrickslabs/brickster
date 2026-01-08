test_that("Lakebase APIs - don't perform", {
  withr::local_envvar(c(
    "DATABRICKS_HOST" = "http://mock_host",
    "DATABRICKS_TOKEN" = "mock_token"
  ))

  expect_error({
    db_lakebase_creds_generate(
      permission_set = "READ_ONLY",
      tables = "main.default.sample_table",
      perform_request = FALSE
    )
  })

  req_cred <- db_lakebase_creds_generate(
    permission_set = "READ_ONLY",
    tables = "main.default.sample_table",
    instance_names = c("sample-instance-a", "sample-instance-b"),
    perform_request = FALSE
  )
  expect_s3_class(req_cred, "httr2_request")
  expect_match(db_request_json(req_cred), "sample-instance-a")
  expect_match(db_request_json(req_cred), "main.default.sample_table")

  req_list <- db_lakebase_list(
    page_size = 5,
    page_token = "page-1",
    perform_request = FALSE
  )
  expect_s3_class(req_list, "httr2_request")

  req_get <- db_lakebase_get(
    name = "sample-instance",
    perform_request = FALSE
  )
  expect_s3_class(req_get, "httr2_request")

  req_find <- db_lakebase_get_by_uid(
    uid = "1111-2222",
    perform_request = FALSE
  )
  expect_s3_class(req_find, "httr2_request")
})
