test_that("job details retain their print class and list access", {
  withr::local_envvar(c(
    DATABRICKS_HOST = "https://mock_host",
    DATABRICKS_TOKEN = "mock_token"
  ))
  local_mocked_bindings(
    db_perform_request = function(req) {
      list(
        job_id = "123",
        creator_user_name = "owner@databricks.com",
        settings = list(name = "job-a")
      )
    },
    .package = "brickster"
  )

  job <- db_jobs_get(job_id = "123")
  expect_s3_class(job, c("db_job", "list"))
  expect_identical(job$job_id, "123")

  job_print <- cli::ansi_strip(paste(capture.output(print(job)), collapse = "\n"))
  expect_match(job_print, "job 123", fixed = TRUE)
  expect_match(job_print, "\n  job-a\n", fixed = TRUE)
  expect_match(job_print, "Owner: owner@databricks.com", fixed = TRUE)
})

test_that("job listings retain printing and pagination metadata", {
  withr::local_envvar(c(
    DATABRICKS_HOST = "https://mock_host",
    DATABRICKS_TOKEN = "mock_token"
  ))
  local_mocked_bindings(
    db_perform_request = function(req) {
      list(
        jobs = list(
          list(job_id = "123", settings = list(name = "job-a")),
          list(job_id = "456", settings = list(name = "job-b"))
        ),
        next_page_token = "next"
      )
    },
    .package = "brickster"
  )

  page <- db_jobs_list()
  expect_s3_class(page, c("db_job_list", "list"))
  purrr::walk(page$jobs, ~ expect_s3_class(.x, c("db_job", "list")))
  expect_identical(page$next_page_token, "next")
  output <- cli::ansi_strip(paste(capture.output(print(page)), collapse = "\n"))
  expect_match(output, "job 123", fixed = TRUE)
  expect_match(output, "job 456", fixed = TRUE)
  expect_match(output, "\n  job-a\n", fixed = TRUE)
  expect_match(output, "\n  job-b\n", fixed = TRUE)
})

test_that("Jobs list wrappers return one full response page by default", {
  withr::local_envvar(c(
    DATABRICKS_HOST = "https://mock_host",
    DATABRICKS_TOKEN = "mock_token"
  ))
  pages <- list(
    jobs = list(jobs = list(list(job_id = "123")), next_page_token = "next+/="),
    runs = list(runs = list(list(run_id = "456")), next_page_token = "next+/=")
  )
  empty_page <- list(
    next_page_token = "empty",
    prev_page_token = "previous",
    future_metadata = "kept"
  )
  local_mocked_bindings(
    db_perform_request = function(req) {
      url <- httr2::url_parse(req$url)
      if (is.null(req$body$data$page_token)) {
        field <- if (endsWith(url$path, "/runs/list")) "runs" else "jobs"
        return(pages[[field]])
      }
      if (identical(req$body$data$page_token, "empty")) return(list())
      expect_identical(req$body$data$page_token, "next+/=")
      empty_page
    },
    .package = "brickster"
  )

  list_pages <- list(
    jobs = db_jobs_list,
    runs = function(...) db_jobs_runs_list(job_id = 1, ...)
  )
  purrr::iwalk(list_pages, function(list_page, field) {
    first <- list_page()
    expect_identical(names(first), names(pages[[field]]))
    expect_identical(purrr::map(first[[field]], unclass), pages[[field]][[field]])
    expect_identical(first$next_page_token, pages[[field]]$next_page_token)
    second <- list_page(page_token = first$next_page_token)
    expect_identical(unclass(second), empty_page)
    expect_identical(unclass(list_page(page_token = second$next_page_token)), list())
  })
})

test_that("Jobs detail wrappers expose the next array page", {
  withr::local_envvar(c(
    DATABRICKS_HOST = "https://mock_host",
    DATABRICKS_TOKEN = "mock_token"
  ))
  local_mocked_bindings(
    db_perform_request = function(req) {
      url <- httr2::url_parse(req$url)
      first <- is.null(req$body$data$page_token)
      if (!first) expect_identical(req$body$data$page_token, "second")
      details <- list(tasks = list(list(task_key = if (first) "a" else "b")))
      if (endsWith(url$path, "/jobs/get")) details <- list(settings = details)
      if (first) details$next_page_token <- "second"
      details
    },
    .package = "brickster"
  )

  get_pages <- list(
    jobs = function(...) db_jobs_get(job_id = 1, ...),
    runs = function(...) db_jobs_runs_get(run_id = 1, ...)
  )
  purrr::iwalk(get_pages, function(get_page, field) {
    first <- get_page()
    second <- get_page(page_token = first$next_page_token)
    expect_null(second$next_page_token)
    if (field == "jobs") {
      first <- first$settings
      second <- second$settings
    }
    expect_identical(first$tasks[[1]]$task_key, "a")
    expect_identical(second$tasks[[1]]$task_key, "b")
  })
})
