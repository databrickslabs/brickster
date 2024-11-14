test_that("Unity Catalog API - don't perform", {

  withr::local_envvar(c(
    "DATABRICKS_HOST" = "mock_host",
    "DATABRICKS_TOKEN" = "mock_token"
  ))

  resp_summary <- db_uc_metastore_summary(perform_request = F)
  expect_s3_class(resp_summary, "httr2_request")

  resp_sc_list <- db_uc_storage_creds_list(perform_request = F)
  expect_s3_class(resp_sc_list, "httr2_request")

  resp_sc_get <- db_uc_storage_creds_get(
    name = "some_name",
    perform_request = F
  )
  expect_s3_class(resp_sc_get, "httr2_request")

  resp_el_list <- db_uc_external_loc_list(
    perform_request = F
  )
  expect_s3_class(resp_el_list, "httr2_request")

  resp_el_get <- db_uc_external_loc_get(
    name = "some_name",
    perform_request = F
  )
  expect_s3_class(resp_el_get, "httr2_request")

  resp_catalog_list <- db_uc_catalogs_list(perform_request = F)
  expect_s3_class(resp_catalog_list, "httr2_request")

  resp_catalog_get <- db_uc_catalogs_get(
    catalog = "some_catalog",
    perform_request = F
  )
  expect_s3_class(resp_catalog_get, "httr2_request")

  resp_schema_list <- db_uc_schemas_list(
    catalog = "some_catalog",
    perform_request = F
  )
  expect_s3_class(resp_schema_list, "httr2_request")

  resp_schema_get <- db_uc_schemas_get(
    catalog = "some_catalog",
    schema = "some_schema",
    perform_request = F
  )
  expect_s3_class(resp_schema_get, "httr2_request")

  resp_table_summaries <- db_uc_table_summaries(
    catalog = "some_catalog",
    max_results = 10,
    perform_request = F
  )
  expect_s3_class(resp_table_summaries, "httr2_request")

  resp_tables_list <- db_uc_tables_list(
    catalog = "some_catalog",
    schema = "some_schema",
    perform_request = F
  )
  expect_s3_class(resp_tables_list, "httr2_request")

  resp_table_get <- db_uc_tables_get(
    catalog = "some_catalog",
    schema = "some_schema",
    table = "some_table",
    perform_request = F
  )
  expect_s3_class(resp_table_get, "httr2_request")

  resp_models_get <- db_uc_models_get(
    catalog = "some_catalog",
    schema = "some_schema",
    model = "some_model",
    perform_request = F
  )
  expect_s3_class(resp_models_get, "httr2_request")

  resp_models_list <- db_uc_models_list(
    catalog = "some_catalog",
    schema = "some_schema",
    perform_request = F
  )
  expect_s3_class(resp_models_list, "httr2_request")

  resp_funcs_get <- db_uc_funcs_get(
    catalog = "some_catalog",
    schema = "some_schema",
    func = "some_func",
    perform_request = F
  )
  expect_s3_class(resp_funcs_get, "httr2_request")

  resp_funcs_list <- db_uc_funcs_list(
    catalog = "some_catalog",
    schema = "some_schema",
    perform_request = F
  )
  expect_s3_class(resp_funcs_list, "httr2_request")

  resp_volumes_list <- db_uc_volumes_list(
    catalog = "some_catalog",
    schema = "some_schema",
    perform_request = F
  )
  expect_s3_class(resp_volumes_list, "httr2_request")



})

skip_on_cran()
skip_unless_authenticated()
skip_unless_aws_workspace()

test_that("Unity Catalog API", {

  expect_no_error({
    resp_summary <- db_uc_metastore_summary()
  })
  expect_type(resp_summary, "list")

  expect_no_error({
    resp_sc_list <- db_uc_storage_creds_list()
  })
  expect_type(resp_sc_list, "list")

  expect_no_error({
    resp_sc_get <- db_uc_storage_creds_get(
      name = resp_sc_list[[1]]$name
    )
  })
  expect_type(resp_sc_get, "list")

  expect_no_error({
    resp_el_list <- db_uc_external_loc_list()
  })
  expect_type(resp_el_list, "list")

  expect_no_error({
    resp_el_get <- db_uc_external_loc_get(
      name = resp_el_list[[1]][[1]]$name
    )
  })
  expect_type(resp_el_get, "list")

  expect_no_error({
    resp_catalog_list <- db_uc_catalogs_list()
  })
  expect_type(resp_catalog_list, "list")

  expect_no_error({
    resp_catalog_get <- db_uc_catalogs_get(
      catalog = resp_catalog_list[[1]]$name
    )
  })
  expect_type(resp_catalog_get, "list")

  expect_no_error({
    resp_schema_list <- db_uc_schemas_list(
      catalog = "main"
    )
  })
  expect_type(resp_schema_list, "list")

  expect_no_error({
    resp_schema_get <- db_uc_schemas_get(
      catalog = "main",
      schema = resp_schema_list[[1]]$name
    )
  })
  expect_type(resp_schema_get, "list")

  expect_no_error({
    resp_table_summaries <- db_uc_table_summaries(
      catalog = "main",
      max_results = 10
    )
  })
  expect_type(resp_table_summaries, "list")

  table_name <- strsplit(resp_table_summaries[[1]][[1]]$full_name, "\\.")[[1]]
  expect_length(table_name, 3L)

  expect_no_error({
    resp_tables_list <- db_uc_tables_list(
      catalog = "main",
      schema = table_name[2]
    )
  })
  expect_type(resp_tables_list, "list")

  expect_no_error({
    resp_table_get <- db_uc_tables_get(
      catalog = "main",
      schema = table_name[2],
      table = table_name[3]
    )
  })
  expect_type(resp_table_get, "list")

})



