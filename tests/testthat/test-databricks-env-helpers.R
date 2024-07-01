test_that(".libPaths helpers", {
  baseline <- .libPaths()
  r_version <- getRversion()
  temp_dir <- tempdir()

  suppressMessages({
    temp_with_version <- add_lib_path(temp_dir, after = 1, version = TRUE)
    temp_without_version <- add_lib_path(temp_dir, after = 1, version = FALSE)
  })

  expect_true(endsWith(temp_with_version, as.character(r_version)))
  expect_equal(temp_without_version, normalizePath(temp_dir, "/"))

  remove_lib_path(temp_without_version, version = TRUE)
  remove_lib_path(temp_without_version, version = FALSE)

  expect_equal(baseline, .libPaths())

})
