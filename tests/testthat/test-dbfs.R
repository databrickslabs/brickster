test_that("DBFS API - don't perform", {

  filename <- file.path("", basename(tempfile(fileext = ".txt")))
  dirname <- file.path("", basename(tempdir()))

  con <- db_dbfs_create(path = filename, perform_request = FALSE)
  expect_s3_class(con, "httr2_request")

  add_block <- db_dbfs_add_block(
    con,
    "hello world",
    convert_to_raw = TRUE,
    perform_request = FALSE
  )
  expect_s3_class(add_block, "httr2_request")

  close <- db_dbfs_close(handle = con, perform_request = FALSE)
  expect_s3_class(close, "httr2_request")

  read <- db_dbfs_read(filename, perform_request = FALSE)
  expect_s3_class(read, "httr2_request")

  status <- db_dbfs_get_status(filename, perform_request = FALSE)
  expect_s3_class(status, "httr2_request")

  list <- db_dbfs_list("/", perform_request = FALSE)
  expect_s3_class(list, "httr2_request")

  mkdirs <- db_dbfs_mkdirs(dirname, perform_request = FALSE)
  expect_s3_class(mkdirs, "httr2_request")

  move <- db_dbfs_move(
    source_path = filename,
    destination_path = file.path(dirname, filename),
    perform_request = FALSE
  )
  expect_s3_class(move, "httr2_request")

  put <- db_dbfs_put(
    path = file.path(dirname, "put.txt"),
    contents = "hello world 2",
    overwrite = TRUE,
    perform_request = FALSE
  )
  expect_s3_class(put, "httr2_request")

  delete <- db_dbfs_delete(dirname, recursive = TRUE, perform_request = FALSE)
  expect_s3_class(delete, "httr2_request")

})

skip_unless_authenticated()
skip_unless_aws_workspace()

test_that("DBFS API", {

  filename <- file.path("", basename(tempfile(fileext = ".txt")))
  dirname <- file.path("", basename(tempdir()))

  con <- db_dbfs_create(path = filename, overwrite = TRUE)
  expect_type(con, "character")

  resp_add_block <- db_dbfs_add_block(con, "hello world", convert_to_raw = TRUE)
  expect_identical(unname(resp_add_block), list())

  resp_close <- db_dbfs_close(handle = con)
  expect_identical(unname(resp_close), list())

  resp_read <- db_dbfs_read(filename)
  expect_identical(resp_read$bytes_read, 11L)
  expect_identical(resp_read$data, "aGVsbG8gd29ybGQ=")

  resp_status <- db_dbfs_get_status(filename)
  expect_identical(resp_status$path, filename)
  expect_identical(resp_status$file_size, 11L)
  expect_false(resp_status$is_dir)

  resp_list <- db_dbfs_list("/")
  expect_type(resp_list, "list")

  resp_mkdirs <- db_dbfs_mkdirs(dirname)
  expect_identical(unname(resp_mkdirs), list())

  resp_move <- db_dbfs_move(
    source_path = filename,
    destination_path = file.path(dirname, filename)
  )
  expect_identical(unname(resp_move), list())

  resp_put <- db_dbfs_put(
    path = file.path(dirname, "put.txt"),
    contents = "hello world 2",
    overwrite = TRUE
  )
  expect_identical(unname(resp_put), list())

  resp_delete <- db_dbfs_delete(dirname, recursive = TRUE)
  expect_identical(unname(resp_delete), list())


})



