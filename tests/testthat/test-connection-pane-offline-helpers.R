test_that("cluster pane follows pages including empty intermediate pages", {
  state <- new.env(parent = emptyenv())
  state$tokens <- list()
  local_mocked_bindings(
    db_perform_request = function(req) {
      query <- httr2::url_parse(req$url)$query
      expect_identical(query$page_size, "100")
      state$tokens[length(state$tokens) + 1L] <- list(query$page_token)
      if (is.null(query$page_token)) {
        return(list(clusters = list(list(cluster_id = "c-1", cluster_name = "first", state = "RUNNING")), next_page_token = "empty+/="))
      }
      if (query$page_token == "empty+/=") return(list(next_page_token = "last"))
      list(clusters = list(list(cluster_id = "c-2", cluster_name = "last", state = "TERMINATED")), next_page_token = "")
    },
    .package = "brickster"
  )
  out <- get_clusters("mock_host", "mock_token")
  expect_identical(out$name, c("[RUNNING] first (c-1)", "[TERMINATED] last (c-2)"))
  expect_identical(out$type, c("cluster", "cluster"))
  expect_identical(state$tokens, list(NULL, "empty+/=", "last"))
})

test_that("empty cluster pane listings return a typed empty frame", {
  local_mocked_bindings(db_perform_request = function(req) list(), .package = "brickster")
  expect_identical(get_clusters("mock_host", "mock_token"), data.frame(name = character(), type = character()))
})

test_that("cluster pane rejects repeated tokens and propagates later page errors", {
  local_mocked_bindings(
    db_cluster_list = function(host, token, page_token = NULL, ...) {
      if (host == "repeats") return(list(next_page_token = "again"))
      if (is.null(page_token)) return(list(next_page_token = "next"))
      cli::cli_abort("Permission denied on later page")
    },
    .package = "brickster"
  )
  expect_error(get_clusters("repeats", "mock_token"), "repeated.*page token")
  expect_error(get_clusters("fails", "mock_token"), "Permission denied on later page")
})

test_that("workspace pane shows Catalog when Unity Catalog is available", {
  local_mocked_bindings(
    db_sql_warehouse_list = function(...) list(),
    db_perform_request = function(req) list(catalogs = list()),
    .package = "brickster"
  )

  objects <- list_objects(host = "mock_host", token = "mock_token")

  expect_identical(objects$type[objects$name == "Catalog"], "metastore")
})

test_that("Unity Catalog pane listings follow all pages, including empty pages", {
  state <- new.env(parent = emptyenv())
  state$requests <- list()
  local_mocked_bindings(
    db_perform_request = function(req) {
      parsed <- httr2::url_parse(req$url)
      resource <- tail(strsplit(parsed$path, "/", fixed = TRUE)[[1]], 1)
      if (endsWith(resource, ".a_model")) return(list(aliases = list()))
      field <- switch(resource, models = "registered_models", versions = "model_versions", resource)
      state$requests[[length(state$requests) + 1L]] <- parsed
      if (is.null(parsed$query$page_token)) {
        return(c(setNames(list(list(list(name = "first", version = "1"))), field), list(next_page_token = "empty+/=")))
      }
      if (parsed$query$page_token == "empty+/=") return(list(next_page_token = "last"))
      setNames(list(list(list(name = "last", version = "2"))), field)
    },
    .package = "brickster"
  )

  cases <- list(
    list(fun = get_catalogs, args = list(), type = "catalog"),
    list(fun = get_schemas, args = list(catalog = "main"), type = "schema"),
    list(fun = get_tables, args = list(catalog = "main", schema = "default"), type = "table"),
    list(fun = get_uc_volumes, args = list(catalog = "main", schema = "default"), type = "volume"),
    list(fun = get_uc_models, args = list(catalog = "main", schema = "default"), type = "model"),
    list(fun = get_uc_functions, args = list(catalog = "main", schema = "default"), type = "func"),
    list(fun = get_uc_model_versions, args = list(catalog = "main", schema = "default", model = "a_model"), type = "version")
  )
  purrr::walk(cases, function(case) {
    state$requests <- list()
    out <- do.call(case$fun, c(case$args, list(host = "mock_host", token = "mock_token")))
    expect_identical(out$name, if (case$type == "version") c("1", "2") else c("first", "last"))
    expect_identical(out$type, rep(case$type, 2))
    expect_length(state$requests, 3L)
    expect_identical(purrr::map(state$requests, ~ .x$query$page_token), list(NULL, "empty+/=", "last"))
    purrr::walk(state$requests, function(parsed) {
      expect_identical(parsed$query$catalog_name, if (case$type == "version") NULL else case$args$catalog)
      expect_identical(parsed$query$schema_name, if (case$type == "version") NULL else case$args$schema)
    })
  })
})

test_that("pane pagination propagates failures and rejects repeated tokens", {
  local_mocked_bindings(
    db_uc_catalogs_list = function(...) list(catalogs = list(list(name = "first")), next_page_token = "again"),
    db_uc_schemas_list = function(page_token = NULL, ...) {
      if (!is.null(page_token)) stop("Permission denied on later page")
      list(schemas = list(list(name = "first")), next_page_token = "next")
    },
    .package = "brickster"
  )
  expect_error(get_catalogs("mock_host", "mock_token"), "repeated.*page token")
  expect_error(get_schemas("main", "mock_host", "mock_token"), "Permission denied")
})

test_that("volume pane details use the named request with browse access enabled", {
  state <- new.env(parent = emptyenv())
  state$requests <- list()
  local_mocked_bindings(
    db_perform_request = function(req) {
      state$requests[[length(state$requests) + 1L]] <- req
      list(name = "later_volume", catalog_name = "main", schema_name = "default",
           full_name = "main.default.later_volume", volume_type = "MANAGED", browse_only = TRUE)
    },
    .package = "brickster"
  )
  out <- get_uc_volume("main", "default", "mock_host", "later_volume", "mock_token")
  expect_length(state$requests, 1L)
  req <- state$requests[[1]]
  expect_identical(req$method, "GET")
  expect_identical(httr2::url_parse(req$url)$path, "/api/2.1/unity-catalog/volumes/main.default.later_volume")
  expect_identical(httr2::url_parse(req$url)$query$include_browse, "true")
  expect_null(req$body)
  expect_identical(out, data.frame(name = c("name", "volume type"), type = c("later_volume", "MANAGED")))
})

test_that("empty paginated model versions return an empty pane frame", {
  local_mocked_bindings(
    db_uc_model_versions_get = function(page_token = NULL, ...) {
      if (is.null(page_token)) return(list(next_page_token = "last"))
      list()
    },
    db_uc_models_get = function(...) list(aliases = list()),
    .package = "brickster"
  )
  out <- get_uc_model_versions("main", "default", "empty", "mock_host", "mock_token")
  expect_identical(out, data.frame(name = character(), type = character()))
})
