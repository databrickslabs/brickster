test_that("job get/list responses add print classes without changing list access", {
  withr::local_envvar(c(
    "DATABRICKS_HOST" = "http://mock_host",
    "DATABRICKS_TOKEN" = "mock_token"
  ))

  local_mocked_bindings(
    db_request = function(...) {
      args <- list(...)
      structure(list(endpoint = args$endpoint), class = "httr2_request")
    },
    db_perform_request = function(req) {
      if (identical(req$endpoint, "jobs/get")) {
        return(list(
          job_id = "123",
          creator_user_name = "owner@databricks.com",
          settings = list(name = "job-a")
        ))
      }

      if (identical(req$endpoint, "jobs/list")) {
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

      cli::cli_abort("Unexpected endpoint in test mock: {req$endpoint}")
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
