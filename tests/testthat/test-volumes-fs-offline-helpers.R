test_that("db_volume_dir_delete recursive mode forces request execution", {
  state <- new.env(parent = emptyenv())
  state$recursive_called <- FALSE
  state$action_perform <- NULL

  local_mocked_bindings(
    db_volume_recursive_delete_contents = function(...) {
      state$recursive_called <- TRUE
      invisible(NULL)
    },
    db_volume_action = function(perform_request = TRUE, ...) {
      state$action_perform <- perform_request
      TRUE
    },
    .package = "brickster"
  )

  out <- db_volume_dir_delete(
    path = "/Volumes/c/s/v/path",
    recursive = TRUE,
    perform_request = FALSE,
    host = "mock_host",
    token = "mock_token"
  )

  expect_true(state$recursive_called)
  expect_true(state$action_perform)
  expect_true(out)
})

test_that("db_volume_upload_dir uploads files and preserves directory structure", {
  local_dir <- withr::local_tempdir()
  subdir <- file.path(local_dir, "nested")
  dir.create(subdir)
  writeLines("a", file.path(local_dir, "f1.txt"))
  writeLines("b", file.path(subdir, "f2.txt"))

  state <- new.env(parent = emptyenv())
  state$created_dirs <- character(0)
  state$upload_paths <- character(0)
  state$performed_n <- NULL

  local_mocked_bindings(
    db_volume_dir_create = function(path, ...) {
      state$created_dirs <- c(state$created_dirs, as.character(path))
      TRUE
    },
    db_volume_action = function(path, perform_request = TRUE, ...) {
      state$upload_paths <- c(state$upload_paths, as.character(path))
      structure(list(path = path), class = "httr2_request")
    },
    .package = "brickster"
  )
  local_mocked_bindings(
    req_perform_parallel = function(requests, ...) {
      state$performed_n <- length(requests)
      vector("list", length(requests))
    },
    .package = "httr2"
  )

  out <- db_volume_upload_dir(
    local_dir = local_dir,
    volume_dir = "/Volumes/c/s/v/upload",
    overwrite = TRUE,
    preserve_structure = TRUE,
    host = "mock_host",
    token = "mock_token"
  )

  expect_true(out)
  expect_true(any(grepl("/upload$", state$created_dirs)))
  expect_true(any(grepl("/upload/nested$", state$created_dirs)))
  expect_identical(state$performed_n, 2L)
  expect_true(any(grepl("f1.txt$", state$upload_paths)))
  expect_true(any(grepl("nested/f2.txt$", state$upload_paths)))
})

test_that("db_volume_upload_dir uploads only top-level files when preserve_structure is FALSE", {
  local_dir <- withr::local_tempdir()
  subdir <- file.path(local_dir, "nested")
  dir.create(subdir)
  writeLines("a", file.path(local_dir, "root.txt"))
  writeLines("b", file.path(subdir, "inner.txt"))

  state <- new.env(parent = emptyenv())
  state$upload_paths <- character(0)

  local_mocked_bindings(
    db_volume_dir_create = function(...) TRUE,
    db_volume_action = function(path, perform_request = TRUE, ...) {
      state$upload_paths <- c(state$upload_paths, as.character(path))
      structure(list(path = path), class = "httr2_request")
    },
    .package = "brickster"
  )
  local_mocked_bindings(
    req_perform_parallel = function(requests, ...) vector("list", length(requests)),
    .package = "httr2"
  )

  out <- db_volume_upload_dir(
    local_dir = local_dir,
    volume_dir = "/Volumes/c/s/v/upload_flat",
    overwrite = TRUE,
    preserve_structure = FALSE,
    host = "mock_host",
    token = "mock_token"
  )

  expect_true(out)
  expect_true(any(grepl("upload_flat/root.txt$", state$upload_paths)))
  expect_false(any(grepl("upload_flat/inner.txt$", state$upload_paths)))
  expect_false(any(grepl("upload_flat/nested/inner.txt$", state$upload_paths)))
})

test_that("db_volume_upload_dir warns and short-circuits for empty directories", {
  local_dir <- withr::local_tempdir()
  state <- new.env(parent = emptyenv())
  state$parallel_called <- FALSE

  local_mocked_bindings(
    db_volume_dir_create = function(...) TRUE,
    db_volume_action = function(path, ...) {
      structure(list(path = path), class = "httr2_request")
    },
    .package = "brickster"
  )
  local_mocked_bindings(
    req_perform_parallel = function(...) {
      state$parallel_called <- TRUE
      list()
    },
    .package = "httr2"
  )

  expect_warning(
    out <- db_volume_upload_dir(
      local_dir = local_dir,
      volume_dir = "/Volumes/c/s/v/empty",
      host = "mock_host",
      token = "mock_token"
    ),
    "No files found in directory"
  )

  expect_true(out)
  expect_false(state$parallel_called)
})
