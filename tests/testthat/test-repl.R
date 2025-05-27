test_that("REPL - helpers", {
  # language function
  expect_equal(lang("r"), "R")
  for (i in c("py", "scala", "sql", "sh")) {
    expect_equal(lang(i), i)
  }
  expect_error(lang("hello"))

  # prompt
  expect_equal(repl_prompt("r"), "[Databricks][R]> ")
  expect_equal(repl_prompt("py"), "[Databricks][py]> ")
  expect_equal(repl_prompt("sql"), "[Databricks][sql]> ")
  expect_equal(repl_prompt("scala"), "[Databricks][scala]> ")
  expect_equal(repl_prompt("sh"), "[Databricks][sh]> ")
  expect_error(repl_prompt("x"))

  # clean command results
  # command results are in form:
  # cmd_res <- list(results = list(
  #   resultType = "",
  #   schema = "",
  #   data = "",
  #   fileNames = list("raw", "raw")
  # ))

  # simple case
  cmd_res <- list(results = list(resultType = "text", data = "hello world"))
  expect_equal(db_context_command_parse(cmd_res, "r"), "hello world")
  expect_equal(db_context_command_parse(cmd_res, "sql"), "hello world")
  expect_equal(db_context_command_parse(cmd_res, "scala"), "hello world")
  expect_equal(db_context_command_parse(cmd_res, "py"), "hello world")

  # # python special case
  # cmd_res <- list(results = list(resultType = "text", data = "<html>hello world</html>"))
  # expect_equal(db_context_command_parse(cmd_res, "py"), NULL)

  # error case
  cmd_res <- list(
    results = list(resultType = "error", summary = "err", cause = "err")
  )
  suppressMessages({
    expect_null(db_context_command_parse(cmd_res, "py"))
  })

  # table output case
  mock_tbl <- jsonlite::fromJSON(jsonlite::toJSON(iris), simplifyDataFrame = F)
  mock_schema <- list(
    list(names = "a"),
    list(names = "b"),
    list(names = "c"),
    list(names = "d"),
    list(names = "e")
  )
  cmd_res <- list(
    results = list(
      resultType = "table",
      data = mock_tbl,
      schema = mock_schema
    )
  )

  capture_output({
    expect_no_error(db_context_command_parse(cmd_res, "py"))
    expect_null(db_context_command_parse(cmd_res, "py"))
  })

  # command error handling
  # command errors are in form:
  # cmd_err <- list(results = list(
  #   summary = "",
  #   cause = ""
  # ))
  cmd_err <- list(results = list(summary = "summary", cause = "cause"))

  expect_equal(handle_cmd_error(cmd_err, "py"), cmd_err$results$cause)
  expect_equal(handle_cmd_error(cmd_err, "sql"), cmd_err$results$summary)
  expect_equal(handle_cmd_error(cmd_err, "scala"), cmd_err$results$summary)
  expect_equal(handle_cmd_error(cmd_err, "r"), cmd_err$results$cause)

  # output should always remove surrounding space
  cmd_err <- list(results = list(summary = " summary ", cause = " cause "))

  expect_equal(handle_cmd_error(cmd_err, "py"), trimws(cmd_err$results$cause))
  expect_equal(
    handle_cmd_error(cmd_err, "sql"),
    trimws(cmd_err$results$summary)
  )
  expect_equal(
    handle_cmd_error(cmd_err, "scala"),
    trimws(cmd_err$results$summary)
  )
  expect_equal(handle_cmd_error(cmd_err, "r"), trimws(cmd_err$results$cause))

  # special case where R output is prefixed with `DATABRICKS_CURRENT_TEMP_CMD__`
  cmd_err_r <- list(
    results = list(
      summary = "summary",
      cause = "DATABRICKS_CURRENT_TEMP_CMD__some_other_content_here_cut_thiscause!!!"
    )
  )
  expect_equal(handle_cmd_error(cmd_err_r, "r"), "cause!!!")
})
