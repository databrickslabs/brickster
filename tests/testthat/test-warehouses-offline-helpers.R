test_that("get_and_start_warehouse starts stopped warehouses and skips running ones", {
  state <- new.env(parent = emptyenv())
  state$idx <- 0L
  state$start_calls <- 0L
  states <- list(
    list(state = "STOPPED"),
    list(state = "STARTING"),
    list(state = "RUNNING")
  )

  local_mocked_bindings(
    db_sql_warehouse_get = function(...) {
      state$idx <- state$idx + 1L
      states[[state$idx]]
    },
    db_sql_warehouse_start = function(...) {
      state$start_calls <- state$start_calls + 1L
      list()
    },
    .package = "brickster"
  )

  out <- get_and_start_warehouse(id = "wh-1", polling_interval = 0)
  expect_identical(state$start_calls, 1L)
  expect_identical(state$idx, 3L)
  expect_identical(out$state, "RUNNING")

  local_mocked_bindings(
    db_sql_warehouse_get = function(...) list(state = "RUNNING"),
    db_sql_warehouse_start = function(...) {
      state$start_calls <- state$start_calls + 1L
      list()
    },
    .package = "brickster"
  )

  out_running <- get_and_start_warehouse(id = "wh-2", polling_interval = 0)
  expect_identical(out_running$state, "RUNNING")
  expect_identical(state$start_calls, 1L)
})
