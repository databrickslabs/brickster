test_that("Databricks Notebook Helpers", {

  # currently running tests outside of a databricks notebook
  expect_false(in_databricks_nb())

})
