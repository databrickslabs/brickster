skip_on_cran()
skip_unless_credentials_set()
skip_unless_authenticated()
skip_unless_aws_workspace()

test_that("Connection Pane Helpers", {

  # current behaviour is if not match return original string
  extract_id1 <- get_id_from_panel_name("meow (1234)")
  extract_id2 <- get_id_from_panel_name("meow (1234) meow")
  extract_id3 <- get_id_from_panel_name("meow(1234)meow")
  extract_id4 <- get_id_from_panel_name("meow meow")

  expect_identical(extract_id1, "1234")
  expect_identical(extract_id2, "1234")
  expect_identical(extract_id3, "1234")
  expect_identical(extract_id4, "meow meow")

  expect_identical(readable_time(1713146793000), "2024-04-15 02:06:33")
  expect_error(readable_time("1713146793000"))

  expect_no_error({
    catalog_items <- get_catalogs(host = db_host(), token = db_token())
  })
  expect_type(catalog_items, "list")

  expect_no_error({
    schema_items <- get_schemas(
      catalog = "main",
      host = db_host(),
      token = db_token()
    )
  })
  expect_type(schema_items, "list")

  expect_no_error({
    table_items <- get_tables(
      catalog = "main",
      schema = "information_schema",
      host = db_host(),
      token = db_token()
    )
  })
  expect_type(table_items, "list")

  expect_no_error({
    table_data_view <- get_table_data(
      catalog = "main",
      schema = "information_schema",
      table = "columns",
      host = db_host(),
      token = db_token()
    )
  })
  expect_type(table_data_view, "list")

  expect_no_error({
    exps <- get_experiments(
      host = db_host(),
      token = db_token()
    )
    exp_id <- get_id_from_panel_name(exps$name[[1]])
    exp_data <- get_experiment(
      id = exp_id,
      host = db_host(),
      token = db_token()
    )
  })
  expect_type(exps, "list")
  expect_type(exp_data, "list")

  expect_no_error({
    models <- get_models(
      host = db_host(),
      token = db_token()
    )
    model_id <- get_id_from_panel_name(models$name[[1]])
    model_data <- get_model_metadata(
      id = model_id,
      host = db_host(),
      token = db_token()
    )
    model_vers <- get_model_versions(
      id = model_id,
      host = db_host(),
      token = db_token()
    )
    model_vers_specific <- get_model_versions(
      id = model_id,
      version = model_vers$name[1],
      host = db_host(),
      token = db_token()
    )

  })
  expect_type(models, "list")
  expect_type(model_data, "list")
  expect_type(model_vers, "list")
  expect_type(model_vers_specific, "list")

  expect_no_error({
    clusters <- get_clusters(
      host = db_host(),
      token = db_token()
    )
    # remove serverless clusters from test as they cause an issue
    clusters <- clusters[!grepl("v2n", clusters$name), ]
    cluster_id <- get_id_from_panel_name(clusters$name[[1]])
    cluster_data <- get_cluster(
      id = cluster_id,
      host = db_host(),
      token = db_token()
    )

  })
  expect_type(clusters, "list")
  expect_type(cluster_data, "list")

  expect_no_error({
    warehouses <- get_warehouses(
      host = db_host(),
      token = db_token()
    )
    warehouse_id <- get_id_from_panel_name(warehouses$name[[1]])
    warehouse_data <- get_warehouse(
      id = warehouse_id,
      host = db_host(),
      token = db_token()
    )
  })
  expect_type(warehouses, "list")
  expect_type(warehouse_data, "list")


  expect_no_error({
    lo_baseline <- list_objects(
      host = db_host(),
      token = db_token()
    )
  })
  expect_type(lo_baseline, "list")

  expect_no_error({
    lo_catalog = list_objects(
      metastore = "some_metastore",
      host = db_host(),
      token = db_token()
    )
  })
  expect_type(lo_catalog, "list")

  expect_no_error({
    lo_schema = list_objects(
      metastore = "some_metastore",
      catalog = "system",
      host = db_host(),
      token = db_token()
    )
  })
  expect_type(lo_schema, "list")

  expect_no_error({
    lo_tables = list_objects(
      metastore = "some_metastore",
      catalog = "system",
      schema = "information_schema",
      host = db_host(),
      token = db_token()
    )
  })
  expect_type(lo_tables, "list")

  expect_no_error({
    lo_table = list_objects(
      metastore = "some_metastore",
      catalog = "system",
      schema = "information_schema",
      table = "catalogs",
      host = db_host(),
      token = db_token()
    )
  })
  expect_type(lo_table, "list")
  expect_identical(lo_table$name, c("metadata", "columns"))
  expect_identical(lo_table$type, c("metadata", "columns"))

  expect_no_error({
    lo_exps = list_objects(
      experiments = "",
      host = db_host(),
      token = db_token()
    )
  })
  expect_type(lo_exps, "list")

  expect_no_error({
    lo_models = list_objects(
      modelregistry = "",
      host = db_host(),
      token = db_token()
    )
  })
  expect_type(lo_models, "list")

  expect_no_error({
    lo_clusters = list_objects(
      clusters = "",
      host = db_host(),
      token = db_token()
    )
  })
  expect_type(lo_clusters, "list")

  expect_no_error({
    lo_warehouses = list_objects(
      warehouses = "",
      host = db_host(),
      token = db_token()
    )
  })
  expect_type(lo_warehouses, "list")

  expect_no_error({
    lo_dbfs = list_objects(
      dbfs = "",
      host = db_host(),
      token = db_token()
    )
  })
  expect_type(lo_dbfs, "list")

  expect_no_error({
    lo_notebooks = list_objects(
      notebooks = "",
      host = db_host(),
      token = db_token()
    )
  })
  expect_type(lo_notebooks, "list")


})
