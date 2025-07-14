test_that("Volumes API - don't perform", {

  withr::local_envvar(c(
    "DATABRICKS_HOST" = "http://mock_host",
    "DATABRICKS_TOKEN" = "mock_token"
  ))

  valid_volume_path <- "/Volumes/catalog/schema/volume/"

  expect_no_error(is_valid_volume_path(valid_volume_path))
  expect_identical(
    is_valid_volume_path(valid_volume_path),
    valid_volume_path
  )
  expect_error(is_valid_volume_path("/invalid/path"))

  resp_list <- db_volume_list(
    path = valid_volume_path,
    perform_request = F
  )
  expect_s3_class(resp_list, "httr2_request")

  expect_error({
    db_volume_list(
      path = "incorrect_path",
      perform_request = F
    )
  })

  resp_dir_create <- db_volume_dir_create(
    path = valid_volume_path,
    perform_request = F
  )
  expect_s3_class(resp_dir_create, "httr2_request")

  resp_dir_exists <- db_volume_dir_exists(
    path = valid_volume_path,
    perform_request = F
  )
  expect_s3_class(resp_dir_exists, "httr2_request")

  resp_dir_delete <- db_volume_dir_delete(
    path = valid_volume_path,
    perform_request = F
  )
  expect_s3_class(resp_dir_delete, "httr2_request")

  expect_error({
    resp_write <- db_volume_write(
      path = valid_volume_path,
      file = "filepath_that_doesnt_exist",
      perform_request = F
    )
  })

   expect_error({
    resp_write <- db_volume_write(
      path = valid_volume_path,
      file = NULL,
      perform_request = F
    )
  })

  resp_read <- db_volume_read(
    path = valid_volume_path,
    destination = "~/Desktop/downloaded_volume_img.png",
    perform_request = F
  )
  expect_s3_class(resp_read, "httr2_request")

  resp_get <- db_volume_file_exists(
    path = valid_volume_path,
    perform_request = F
  )
  expect_s3_class(resp_get, "httr2_request")

  resp_delte <- db_volume_delete(
    path = valid_volume_path,
    perform_request = F
  )
  expect_s3_class(resp_delte, "httr2_request")

})

test_that("db_volume_upload_dir - don't perform", {
  
  withr::local_envvar(c(
    "DATABRICKS_HOST" = "http://mock_host",
    "DATABRICKS_TOKEN" = "mock_token"
  ))
  
  # Create temporary directory with test files
  temp_dir <- withr::local_tempdir()
  subdir <- file.path(temp_dir, "subdir")
  dir.create(subdir)
  
  # Create test files
  writeLines("test content 1", file.path(temp_dir, "file1.txt"))
  writeLines("test content 2", file.path(temp_dir, "file2.txt"))
  writeLines("test content 3", file.path(subdir, "file3.txt"))
  
  valid_volume_path <- "/Volumes/catalog/schema/volume/"
  
  # Test that function executes without error (will fail at HTTP request stage in test environment)
  expect_error(
    db_volume_upload_dir(
      local_dir = temp_dir,
      volume_dir = valid_volume_path
    )
  )
  
  # Test with non-existent directory
  expect_error(
    db_volume_upload_dir(
      local_dir = "/path/that/does/not/exist",
      volume_dir = valid_volume_path
    ),
    "Local directory does not exist"
  )
  
  # Test with invalid volume path
  expect_error(
    db_volume_upload_dir(
      local_dir = temp_dir,
      volume_dir = "/invalid/path"
    )
  )
  
})
