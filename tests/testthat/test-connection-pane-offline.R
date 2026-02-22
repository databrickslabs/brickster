test_that("get_table_data returns expected metadata and column summaries", {
  out_view <- with_mocked_bindings(
    get_table_data(
      catalog = "main",
      schema = "s",
      table = "v",
      host = "mock_host",
      token = "mock_token",
      metadata = TRUE
    ),
    db_uc_tables_get = function(...) {
      list(
        table_type = "VIEW",
        data_source_format = "VIEW",
        view_definition = "SELECT 1",
        full_name = "main.s.v",
        owner = "owner",
        created_at = 1713146793000,
        created_by = "creator",
        updated_at = 1713146793000,
        updated_by = "updater"
      )
    },
    .package = "brickster"
  )

  expect_true(all(c("table type", "view definition", "full name") %in% out_view$name))

  out_table <- with_mocked_bindings(
    get_table_data(
      catalog = "main",
      schema = "s",
      table = "t",
      host = "mock_host",
      token = "mock_token",
      metadata = TRUE
    ),
    db_uc_tables_get = function(...) {
      list(
        table_type = "TABLE",
        data_source_format = "TABLE",
        full_name = "main.s.t",
        owner = "owner",
        storage_location = "s3://bucket/path",
        properties = list(
          "delta.lastCommitTimestamp" = "1713146793000",
          "delta.minReaderVersion" = "1",
          "delta.minWriterVersion" = "7"
        ),
        created_at = 1713146793000,
        created_by = "creator",
        updated_at = 1713146793000,
        updated_by = "updater"
      )
    },
    .package = "brickster"
  )

  expect_true(all(c("last commit at", "min reader version", "min writer version") %in% out_table$name))

  out_cols <- with_mocked_bindings(
    get_table_data(
      catalog = "main",
      schema = "s",
      table = "t",
      host = "mock_host",
      token = "mock_token",
      metadata = FALSE
    ),
    db_uc_tables_get = function(...) {
      list(columns = list(
        list(name = "id", type_name = "INT", nullable = TRUE),
        list(name = "name", type_name = "STRING", nullable = FALSE)
      ))
    },
    .package = "brickster"
  )

  expect_identical(out_cols$name, c("id", "name"))
  expect_identical(
    out_cols$type,
    c("INT (nullable: TRUE)", "STRING (nullable: FALSE)")
  )
})

test_that("get_uc_model_versions applies aliases and returns per-version metadata", {
  versions_payload <- list(list(
    list(
      version = "1",
      created_at = 1713146793000,
      created_by = "a",
      updated_at = 1713146793000,
      updated_by = "b",
      run_id = "run-1",
      run_workspace_id = "ws-1",
      source = "dbfs:/model/1",
      status = "READY",
      id = "id-1"
    ),
    list(
      version = "2",
      created_at = 1713146793000,
      created_by = "a",
      updated_at = 1713146793000,
      updated_by = "b",
      run_id = "run-2",
      run_workspace_id = "ws-2",
      source = "dbfs:/model/2",
      status = "READY",
      id = "id-2"
    )
  ))

  model_payload <- list(
    aliases = list(list(alias_name = "champion", version_num = "2"))
  )

  out_all <- with_mocked_bindings(
    get_uc_model_versions(
      catalog = "main",
      schema = "s",
      model = "m",
      host = "mock_host",
      token = "mock_token"
    ),
    db_uc_model_versions_get = function(...) versions_payload,
    db_uc_models_get = function(...) model_payload,
    .package = "brickster"
  )

  out_one <- with_mocked_bindings(
    get_uc_model_versions(
      catalog = "main",
      schema = "s",
      model = "m",
      version = "2",
      host = "mock_host",
      token = "mock_token"
    ),
    db_uc_model_versions_get = function(...) versions_payload,
    db_uc_models_get = function(...) model_payload,
    .package = "brickster"
  )

  expect_true(any(grepl("^2 \\(@champion\\)$", out_all$name)))
  expect_true(all(c("run id", "status", "id") %in% out_one$name))
})

test_that("catalog list helper returns stable typed frames for non-empty and empty inputs", {
  out_catalogs <- with_mocked_bindings(
    get_catalogs(host = "mock_host", token = "mock_token"),
    db_uc_catalogs_list = function(...) list(list(name = "c1"), list(name = "c2")),
    .package = "brickster"
  )

  expect_identical(out_catalogs$name, c("c1", "c2"))
  expect_true(all(out_catalogs$type == "catalog"))

  out_catalogs_empty <- with_mocked_bindings(
    get_catalogs(host = "mock_host", token = "mock_token"),
    db_uc_catalogs_list = function(...) list(),
    .package = "brickster"
  )

  expect_identical(nrow(out_catalogs_empty), 0L)
  expect_s3_class(out_catalogs_empty, "data.frame")
})

test_that("get_schema_objects summarizes only object groups that contain rows", {
  out <- with_mocked_bindings(
    get_schema_objects(
      catalog = "main",
      schema = "s",
      host = "mock_host",
      token = "mock_token"
    ),
    get_tables = function(...) data.frame(name = c("t1", "t2"), type = "table"),
    get_uc_volumes = function(...) data.frame(name = "v1", type = "volume"),
    get_uc_models = function(...) data.frame(name = character(0), type = character(0)),
    get_uc_functions = function(...) data.frame(name = c("f1", "f2", "f3"), type = "func"),
    .package = "brickster"
  )

  expect_true(all(c("tables (2)", "volumes (1)", "funcs (3)") %in% out$name))
  expect_false(any(grepl("^models", out$name)))
})

test_that("MLflow model helpers return expected version labels and metadata rows", {
  payload <- list(list(
    list(
      version = "1",
      current_stage = "None",
      creation_timestamp = 1713146793000,
      last_updated_timestamp = 1713146793000,
      user_id = "u1",
      source = "dbfs:/m/1",
      status = "READY"
    ),
    list(
      version = "2",
      current_stage = "Production",
      creation_timestamp = 1713146793000,
      last_updated_timestamp = 1713146793000,
      user_id = "u2",
      source = "dbfs:/m/2",
      status = "READY"
    )
  ))

  out_all <- with_mocked_bindings(
    get_model_versions(
      id = "model_a",
      host = "mock_host",
      token = "mock_token"
    ),
    db_mlflow_registered_models_search_versions = function(...) payload,
    .package = "brickster"
  )

  out_one <- with_mocked_bindings(
    get_model_versions(
      id = "model_a",
      version = "2 (Production)",
      host = "mock_host",
      token = "mock_token"
    ),
    db_mlflow_registered_models_search_versions = function(...) payload,
    .package = "brickster"
  )

  expect_identical(out_all$name, c("1", "2 (Production)"))
  expect_true(all(c("current stage", "source", "status") %in% out_one$name))
})

test_that("compute and model-registry list helpers format display labels", {
  out_models <- with_mocked_bindings(
    get_models(host = "mock_host", token = "mock_token"),
    db_mlflow_registered_models_list = function(...) {
      list(registered_models = list(list(name = "model_a"), list(name = "model_b")))
    },
    .package = "brickster"
  )
  expect_identical(out_models$name, c("model_a", "model_b"))

  out_model_meta <- with_mocked_bindings(
    get_model_metadata(id = "model_a", host = "mock_host", token = "mock_token"),
    db_mlflow_registered_model_details = function(...) {
      list(
        name = "model_a",
        latest_versions = list(list(version = "7")),
        user_id = "u123",
        creation_timestamp = 1713146793000,
        last_updated_timestamp = 1713146793000,
        permission_level = "CAN_READ",
        id = "m-id"
      )
    },
    .package = "brickster"
  )
  expect_true(all(c("latest version", "permissions", "id") %in% out_model_meta$name))

  out_clusters <- with_mocked_bindings(
    get_clusters(host = "mock_host", token = "mock_token"),
    db_cluster_list = function(...) {
      list(list(state = "RUNNING", cluster_name = "c-a", cluster_id = "cid-a"))
    },
    .package = "brickster"
  )
  expect_identical(out_clusters$name, "[RUNNING] c-a (cid-a)")

  out_warehouses <- with_mocked_bindings(
    get_warehouses(host = "mock_host", token = "mock_token"),
    db_sql_warehouse_list = function(...) {
      list(list(state = "STOPPED", name = "w-a", id = "wid-a"))
    },
    .package = "brickster"
  )
  expect_identical(out_warehouses$name, "[STOPPED] w-a (wid-a)")
})

test_that("close_workspace notifies connection observer when configured", {
  state <- new.env(parent = emptyenv())
  state$closed <- NULL

  withr::local_options(list(
    connectionObserver = list(
      connectionClosed = function(type, host) {
        state$closed <- list(type = type, host = host)
      }
    )
  ))

  close_workspace(host = "my-host.cloud.databricks.com")

  expect_identical(state$closed$type, "workspace")
  expect_identical(state$closed$host, "my-host.cloud.databricks.com")
})
