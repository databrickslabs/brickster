skip_unless_credentials_set()

test_that("Execution Contexts API - don't perform", {

  resp_ctx_create <- db_context_create(
    cluster_id = "some_cluster_id",
    language = "python",
    perform_request = F
  )
  expect_s3_class(resp_ctx_create, "httr2_request")

  langs <- c("python", "sql", "scala", "r")
  for (l in langs) {
    expect_no_error({
      db_context_create(
        cluster_id = "some_cluster_id",
        language = l,
        perform_request = F
      )
    })
  }

  # language must match list
  expect_error({
    db_context_create(
      cluster_id = "some_cluster_id",
      language = "some_language",
      perform_request = F
    )
  })

  resp_ctx_destroy <- db_context_destroy(
    cluster_id = "some_cluster_id",
    context_id = "some_context_id",
    perform_request = F
  )
  expect_s3_class(resp_ctx_create, "httr2_request")

  resp_ctx_status <- db_context_status(
    cluster_id = "some_cluster_id",
    context_id = "some_context_id",
    perform_request = F
  )
  expect_s3_class(resp_ctx_status, "httr2_request")

  resp_ctx_cmd_run <- db_context_command_run(
    cluster_id = "some_cluster_id",
    context_id = "some_context_id",
    language = "python",
    command = "some cmd",
    perform_request = F
  )
  expect_s3_class(resp_ctx_cmd_run, "httr2_request")

  # can't use both command and command_file args
  expect_error({
    db_context_command_run(
      cluster_id = "some_cluster_id",
      context_id = "some_context_id",
      language = "python",
      command = "1+1",
      command_file = "~/some/file/path/cmd.txt",
      perform_request = F
    )
  })

  resp_ctx_cmd_status <- db_context_command_status(
    cluster_id = "some_cluster_id",
    context_id = "some_context_id",
    command_id = "some_cmd_id",
    perform_request = F
  )
  expect_s3_class(resp_ctx_cmd_status, "httr2_request")

  resp_ctx_cmd_cancel <- db_context_command_cancel(
    cluster_id = "some_cluster_id",
    context_id = "some_context_id",
    command_id = "some_cmd_id",
    perform_request = F
  )
  expect_s3_class(resp_ctx_cmd_cancel, "httr2_request")

})
