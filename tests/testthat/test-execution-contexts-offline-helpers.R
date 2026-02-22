test_that("execution context endpoints perform requests when requested", {
  req <- structure(list(), class = "httr2_request")
  state <- new.env(parent = emptyenv())
  state$endpoint <- NULL

  local_mocked_bindings(
    db_request = function(endpoint, ...) {
      state$endpoint <- endpoint
      req
    },
    db_perform_request = function(req) {
      switch(
        state$endpoint,
        "contexts/create" = list(id = "ctx-1"),
        "contexts/destroy" = list(status = "ok"),
        "contexts/status" = list(status = "running"),
        "commands/status" = list(status = "Finished"),
        "commands/cancel" = list(cancelled = TRUE),
        list()
      )
    },
    .package = "brickster"
  )
  local_mocked_bindings(
    req_url_query = function(req, ...) req,
    .package = "httr2"
  )

  expect_identical(
    db_context_create(
      cluster_id = "c-1",
      language = "python",
      host = "mock_host",
      token = "mock_token",
      perform_request = TRUE
    )$id,
    "ctx-1"
  )

  expect_identical(
    db_context_destroy(
      cluster_id = "c-1",
      context_id = "ctx-1",
      host = "mock_host",
      token = "mock_token",
      perform_request = TRUE
    )$status,
    "ok"
  )

  expect_identical(
    db_context_status(
      cluster_id = "c-1",
      context_id = "ctx-1",
      host = "mock_host",
      token = "mock_token",
      perform_request = TRUE
    )$status,
    "running"
  )

  expect_identical(
    db_context_command_status(
      cluster_id = "c-1",
      context_id = "ctx-1",
      command_id = "cmd-1",
      host = "mock_host",
      token = "mock_token",
      perform_request = TRUE
    )$status,
    "Finished"
  )

  expect_true(
    db_context_command_cancel(
      cluster_id = "c-1",
      context_id = "ctx-1",
      command_id = "cmd-1",
      host = "mock_host",
      token = "mock_token",
      perform_request = TRUE
    )$cancelled
  )
})

test_that("db_context_command_run supports command_file and returns command metadata", {
  tmp <- tempfile(fileext = ".py")
  writeLines("print(1)", tmp)

  req <- structure(list(), class = "httr2_request")

  local_mocked_bindings(
    db_request = function(...) req,
    db_perform_request = function(req) list(id = "cmd-123"),
    .package = "brickster"
  )
  local_mocked_bindings(
    form_file = function(path) paste0("FORM::", basename(path)),
    .package = "curl"
  )
  local_mocked_bindings(
    req_body_multipart = function(req, ...) req,
    .package = "httr2"
  )

  out <- db_context_command_run(
    cluster_id = "c-1",
    context_id = "ctx-1",
    language = "python",
    command_file = tmp,
    host = "mock_host",
    token = "mock_token",
    perform_request = TRUE
  )

  expect_identical(out$id, "cmd-123")
  expect_identical(out$language, "python")
})

test_that("db_context_command_run_and_wait polls until done and supports parsed/raw outputs", {
  state <- new.env(parent = emptyenv())
  state$status_calls <- 0L

  local_mocked_bindings(
    Sys.sleep = function(...) NULL,
    .package = "base"
  )
  local_mocked_bindings(
    db_context_command_run = function(...) list(id = "cmd-1", language = "python"),
    db_context_command_status = function(...) {
      state$status_calls <- state$status_calls + 1L
      if (state$status_calls == 1L) {
        return(list(status = "Running", results = list(resultType = "text", data = "wait")))
      }
      list(status = "Finished", results = list(resultType = "text", data = "done"))
    },
    db_context_command_parse = function(x, language) {
      paste("parsed", language, x$status)
    },
    .package = "brickster"
  )

  parsed <- db_context_command_run_and_wait(
    cluster_id = "c-1",
    context_id = "ctx-1",
    language = "python",
    command = "print(1)",
    parse_result = TRUE,
    host = "mock_host",
    token = "mock_token"
  )

  expect_identical(parsed, "parsed python Finished")
  expect_true(state$status_calls >= 2L)

  local_mocked_bindings(
    db_context_command_status = function(...) {
      list(status = "Finished", results = list(resultType = "text", data = "done"))
    },
    .package = "brickster"
  )

  raw_status <- db_context_command_run_and_wait(
    cluster_id = "c-1",
    context_id = "ctx-1",
    language = "python",
    command = "print(1)",
    parse_result = FALSE,
    host = "mock_host",
    token = "mock_token"
  )

  expect_identical(raw_status$status, "Finished")

  expect_error(
    db_context_command_run_and_wait(
      cluster_id = "c-1",
      context_id = "ctx-1",
      language = "python",
      command = "print(1)",
      parse_result = "no",
      host = "mock_host",
      token = "mock_token"
    ),
    "is.logical"
  )
})
