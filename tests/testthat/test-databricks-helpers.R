test_that("databricks helpers - runtime detection", {

  withr::with_envvar(
    new = c(DATABRICKS_RUNTIME_VERSION = ""),
    {
      expect_no_error(on_databricks())
      expect_identical(on_databricks(), FALSE)
      expect_identical(determine_brickster_venv(), "r-brickster")

    }
  )

  withr::with_envvar(
    new = c(DATABRICKS_RUNTIME_VERSION = "14.0"),
    {
      expect_no_error(on_databricks())
      expect_identical(on_databricks(), TRUE)
      expect_null(determine_brickster_venv())

    }
  )

})
