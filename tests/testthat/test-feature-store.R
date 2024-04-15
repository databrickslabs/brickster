test_that("Feature Store API - don't perform", {
  resp_search <- db_feature_tables_search(perform_request = FALSE)
  expect_s3_class(resp_search, "httr2_request")

  resp_get <- db_feature_tables_get(
    "some_table",
    perform_request = FALSE
  )
  expect_s3_class(resp_get, "httr2_request")

  resp_tbl_features <- db_feature_table_features(
    "some_table",
    perform_request = FALSE
  )
  expect_s3_class(resp_tbl_features, "httr2_request")

})

skip_unless_authenticated()
skip_unless_aws_workspace()

test_that("Feature Store API", {

  expect_no_error({
    resp_search <- db_feature_tables_search()
  })
  expect_type(resp_search, "list")

  expect_no_error({
    resp_get <- db_feature_tables_get(
      resp_search$feature_tables[[1]]$name
    )
  })
  expect_type(resp_get, "list")

  expect_no_error({
    resp_tbl_ft <- db_feature_table_features(
      resp_search$feature_tables[[1]]$name
    )
  })
  expect_type(resp_tbl_ft, "list")

})
