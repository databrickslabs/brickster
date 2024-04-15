test_that("Volumes API - don't perform", {

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



