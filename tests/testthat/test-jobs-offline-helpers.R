test_that("job get/list responses add print classes without changing list access", {
  withr::local_envvar(c(
    "DATABRICKS_HOST" = "http://mock_host",
    "DATABRICKS_TOKEN" = "mock_token"
  ))

  local_mocked_bindings(
    db_perform_request = function(req) {
      if (endsWith(httr2::url_parse(req$url)$path, "/jobs/get")) {
        return(list(
          job_id = "123",
          creator_user_name = "owner@databricks.com",
          settings = list(name = "job-a")
        ))
      }

      if (endsWith(httr2::url_parse(req$url)$path, "/jobs/list")) {
        return(list(
          jobs = list(
            list(
              job_id = "123",
              creator_user_name = "owner@databricks.com",
              settings = list(name = "job-a")
            ),
            list(
              job_id = "456",
              creator_user_name = "owner2@databricks.com",
              settings = list(name = "job-b")
            )
          )
        ))
      }

      cli::cli_abort("Unexpected endpoint in test mock: {req$url}")
    },
    .package = "brickster"
  )

  job <- db_jobs_get(job_id = "123", perform_request = TRUE)
  jobs <- db_jobs_list(perform_request = TRUE)

  expect_type(job, "list")
  expect_s3_class(job, c("db_job", "list"))
  expect_identical(job$job_id, "123")

  expect_type(jobs, "list")
  expect_s3_class(jobs, c("db_job_list", "list"))
  expect_s3_class(jobs[[1]], c("db_job", "list"))
  expect_identical(jobs[[2]]$job_id, "456")

  job_print <- cli::ansi_strip(paste(capture.output(print(job)), collapse = "\n"))
  jobs_print <- cli::ansi_strip(paste(capture.output(print(jobs)), collapse = "\n"))

  expect_true(grepl("job 123", job_print, fixed = TRUE))
  expect_true(grepl("\n  job-a\n", job_print, fixed = TRUE))
  expect_true(grepl("Owner: owner@databricks.com", job_print, fixed = TRUE))

  expect_true(grepl("[[1]]", jobs_print, fixed = TRUE))
  expect_true(grepl("job 123", jobs_print, fixed = TRUE))
  expect_true(grepl("job 456", jobs_print, fixed = TRUE))
  expect_true(grepl("\n  job-a\n", jobs_print, fixed = TRUE))
  expect_true(grepl("\n  job-b\n", jobs_print, fixed = TRUE))
})

test_that("Jobs list wrappers preserve full page metadata on request", {
  withr::local_envvar(c(DATABRICKS_HOST = "https://mock_host", DATABRICKS_TOKEN = "mock_token"))
  local_mocked_bindings(
    db_perform_request = function(req) {
      query <- httr2::url_parse(req$url)$query
      field <- if (endsWith(httr2::url_parse(req$url)$path, "/runs/list")) "runs" else "jobs"
      if (is.null(query$page_token)) {
        return(c(setNames(list(list(list(job_id = "123"))), field), list(next_page_token = "next+/=", future_metadata = "kept")))
      }
      expect_identical(query$page_token, "next+/=")
      list(prev_page_token = "previous", future_metadata = "empty page")
    },
    .package = "brickster"
  )
  purrr::walk(list(db_jobs_list, function(...) db_jobs_runs_list(job_id = 1, ...)), function(list_page) {
    first <- list_page(return_response = TRUE)
    expect_identical(first$next_page_token, "next+/=")
    expect_identical(first$future_metadata, "kept")
    second <- list_page(page_token = first$next_page_token, return_response = TRUE)
    expect_identical(second, list(prev_page_token = "previous", future_metadata = "empty page"))
  })
  expect_identical(db_jobs_runs_list(job_id = 1), list(list(job_id = "123")))
})

test_that("Jobs detail wrappers expose the next array page", {
  withr::local_envvar(c(DATABRICKS_HOST = "https://mock_host", DATABRICKS_TOKEN = "mock_token"))
  local_mocked_bindings(
    db_perform_request = function(req) {
      query <- httr2::url_parse(req$url)$query
      if (is.null(query$page_token)) return(list(tasks = list(list(task_key = "a")), next_page_token = "second"))
      expect_identical(query$page_token, "second")
      list(tasks = list(list(task_key = "b")))
    },
    .package = "brickster"
  )
  purrr::walk(list(function(...) db_jobs_get(job_id = 1, ...), function(...) db_jobs_runs_get(run_id = 1, ...)), function(get_page) {
    first <- get_page()
    second <- get_page(page_token = first$next_page_token)
    expect_identical(first$tasks[[1]]$task_key, "a")
    expect_identical(second$tasks[[1]]$task_key, "b")
    expect_null(second$next_page_token)
  })
})
