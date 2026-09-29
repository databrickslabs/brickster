test_that("page collection preserves cluster records across empty pages", {
  state <- new.env(parent = emptyenv())
  state$tokens <- list()
  first <- list(cluster_id = "c-1", spark_conf = list(setting = "value"))
  last <- list(cluster_id = "c-2")
  local_mocked_bindings(
    db_perform_request = function(req) {
      query <- httr2::url_parse(req$url)$query
      expect_identical(query$page_size, "100")
      state$tokens[length(state$tokens) + 1L] <- list(query$page_token)
      if (is.null(query$page_token)) return(list(next_page_token = "first"))
      if (query$page_token == "first") {
        return(list(clusters = list(first), next_page_token = "empty", prev_page_token = "start"))
      }
      if (query$page_token == "empty") return(list(clusters = list(), next_page_token = "last"))
      list(clusters = list(last), next_page_token = "", prev_page_token = "empty")
    },
    .package = "brickster"
  )

  out <- db_list_all_pages(db_cluster_list, page_size = 100, host = "mock_host", token = "mock_token")
  expect_identical(out, list(new_db_cluster(first), new_db_cluster(last)))
  expect_identical(state$tokens, list(NULL, "first", "empty", "last"))
})

test_that("page collection removes only top-level pagination metadata", {
  state <- new.env(parent = emptyenv())
  state$bodies <- list()
  first <- list(type = "RUNNING", details = list(total_count = 2, next_page_token = "nested"))
  last <- list(type = "TERMINATING")
  local_mocked_bindings(
    db_perform_request = function(req) {
      state$bodies[[length(state$bodies) + 1L]] <- req$body$data
      more <- is.null(req$body$data$page_token)
      list(
        events = list(if (more) first else last),
        next_page_token = if (more) "next" else "",
        prev_page_token = "previous",
        next_page = list(offset = 1),
        total_count = 0,
        has_more = more,
        has_next_page = more
      )
    },
    .package = "brickster"
  )

  out <- db_list_all_pages(
    db_cluster_events, cluster_id = "c-1", start_time = 1790553600000,
    event_types = list("RUNNING", "TERMINATING"), page_size = 500,
    host = "mock_host", token = "mock_token"
  )
  expect_identical(out, list(first, last))
  expect_length(state$bodies, 2L)
  expect_identical(state$bodies[[1]], list(
    cluster_id = "c-1", start_time = 1790553600000,
    event_types = list("RUNNING", "TERMINATING"), order = "DESC", page_size = 500
  ))
  expect_identical(state$bodies[[2]], c(state$bodies[[1]], list(page_token = "next")))
})

test_that("page collection works with job listings without a field argument", {
  local_mocked_bindings(
    db_perform_request = function(req) {
      if (is.null(req$body$data$page_token)) {
        return(list(jobs = list(list(job_id = "1")), next_page_token = "next", has_more = TRUE))
      }
      list(jobs = list(list(job_id = "2")), has_more = FALSE)
    },
    .package = "brickster"
  )

  out <- db_list_all_pages(db_jobs_list, host = "mock_host", token = "mock_token")
  expect_identical(purrr::map_chr(out, "job_id"), c("1", "2"))
  purrr::walk(out, ~ expect_s3_class(.x, "db_job"))
})

test_that("empty listings return an empty list without metadata", {
  state <- new.env(parent = emptyenv())
  local_mocked_bindings(db_perform_request = function(req) state$page, .package = "brickster")

  purrr::walk(list(
    list(),
    list(events = list()),
    list(events = NULL, next_page_token = "", prev_page_token = "", total_count = 0, has_more = FALSE)
  ), function(page) {
    state$page <- page
    expect_identical(
      db_list_all_pages(db_cluster_events, cluster_id = "c-1", host = "mock_host", token = "mock_token"),
      list()
    )
  })
})

test_that("page collection rejects repeated tokens and propagates later errors", {
  local_mocked_bindings(
    db_cluster_list = function(host, page_token = NULL) {
      if (host == "repeats") return(list(next_page_token = "again"))
      if (is.null(page_token)) return(list(clusters = list(list(cluster_id = "first")), next_page_token = "next"))
      cli::cli_abort("Permission denied on later page")
    },
    .package = "brickster"
  )

  expect_error(db_list_all_pages(db_cluster_list, host = "repeats"), "repeated.*page token")
  expect_error(db_list_all_pages(db_cluster_list, host = "fails"), "Permission denied on later page")
})
