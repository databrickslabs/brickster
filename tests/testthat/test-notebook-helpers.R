test_that("Databricks Notebook Helpers", {

  # currently running tests outside of a databricks notebook
  expect_false(in_databricks_nb())
  expect_no_error(notebook_use_posit_repo())
  expect_no_error(notebook_enable_htmlwidgets())

})
