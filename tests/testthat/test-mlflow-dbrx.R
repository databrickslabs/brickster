test_that("Unity Catalog API - don't perform", {

  resp_list <- db_mlflow_registered_models_list(
    perform_request = F
  )
  expect_s3_class(resp_list, "httr2_request")

  resp_search <- db_mlflow_registered_models_search(
    perform_request = F
  )
  expect_s3_class(resp_search, "httr2_request")

  resp_search_v <- db_mlflow_registered_models_search_versions(
    name = "some_name",
    max_results = 1,
    perform_request = F
  )
  expect_s3_class(resp_search_v, "httr2_request")

  resp_details <- db_mlflow_registered_model_details(
    name = "some_name",
    perform_request = F
  )
  expect_s3_class(resp_details, "httr2_request")

  resp_tran_stg <- db_mlflow_model_transition_stage(
    name = "some_name",
    version = 1,
    stage = "Production",
    perform_request = F
  )
  expect_s3_class(resp_tran_stg, "httr2_request")

  resp_tran_stg_req <- db_mlflow_model_transition_req(
    name = "some_name",
    version = 1,
    stage = "Production",
    perform_request = F
  )
  expect_s3_class(resp_tran_stg_req, "httr2_request")

  resp_tran_open_req <- db_mlflow_model_open_transition_reqs(
    name = "some_name",
    version = 1,
    perform_request = F
  )
  expect_s3_class(resp_tran_open_req, "httr2_request")

  resp_tran_approve_req <- db_mlflow_model_approve_transition_req(
    name = "some_name",
    version = 1,
    stage = "Production",
    perform_request = F
  )
  expect_s3_class(resp_tran_approve_req, "httr2_request")

  resp_tran_reject_req <- db_mlflow_model_reject_transition_req(
    name = "some_name",
    version = 1,
    stage = "Production",
    perform_request = F
  )
  expect_s3_class(resp_tran_reject_req, "httr2_request")

  resp_tran_del_req <- db_mlflow_model_delete_transition_req(
    name = "some_name",
    version = 1,
    stage = "Production",
    creator = "some_creator",
    perform_request = F
  )
  expect_s3_class(resp_tran_del_req, "httr2_request")

  resp_version_comment <- db_mlflow_model_version_comment(
    name = "some_name",
    version = 1,
    comment = "some_comment",
    perform_request = F
  )
  expect_s3_class(resp_version_comment, "httr2_request")

  resp_version_edit_comment <- db_mlflow_model_version_comment_edit(
    id = "some_id",
    comment = "some_comment_changed",
    perform_request = F
  )
  expect_s3_class(resp_version_edit_comment, "httr2_request")

  resp_version_del_comment <- db_mlflow_model_version_comment_delete(
    id = "some_id",
    perform_request = F
  )
  expect_s3_class(resp_version_del_comment, "httr2_request")


})

skip_unless_authenticated()
skip_unless_aws_workspace()

test_that("Unity Catalog API", {

  expect_no_error({
    resp_list <- db_mlflow_registered_models_list(
      max_results = 1
    )
  })
  expect_type(resp_list, "list")

  expect_no_error({
    resp_search <- db_mlflow_registered_models_search(
      max_results = 1
    )
  })
  expect_type(resp_search, "list")

  expect_no_error({
    resp_search_v <- db_mlflow_registered_models_search_versions(
      name = resp_search$registered_models[[1]]$name,
      max_results = 1
    )
  })
  expect_type(resp_search_v, "list")

  expect_no_error({
    resp_details <- db_mlflow_registered_model_details(
      name = resp_search$registered_models[[1]]$name
    )
  })
  expect_type(resp_details, "list")

  expect_no_error({
    resp_tran_open_req <- db_mlflow_model_open_transition_reqs(
      name = resp_search$registered_models[[1]]$name,
      version = 1
    )
  })
  expect_type(resp_tran_open_req, "list")

})


