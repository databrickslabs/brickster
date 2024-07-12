skip_unless_credentials_set()
test_that("Vector Search APIs - don't perform", {

  expect_no_error({
    req_vse_create <- db_vs_endpoints_create(
      name = "mock_endpoint",
      perform_request = FALSE
    )
  })
  expect_s3_class(req_vse_create, "httr2_request")

  expect_no_error({
    req_vse_delete <- db_vs_endpoints_delete(
      endpoint = "mock_endpoint",
      perform_request = FALSE
    )
  })
  expect_s3_class(req_vse_delete, "httr2_request")

  expect_no_error({
    req_vse_get <- db_vs_endpoints_get(
      endpoint = "mock_endpoint",
      perform_request = FALSE
    )
  })
  expect_s3_class(req_vse_get, "httr2_request")

  expect_no_error({
    req_vse_list <- db_vs_endpoints_list(
      page_token = "mock_page_token",
      perform_request = FALSE
    )
  })
  expect_s3_class(req_vse_list, "httr2_request")

  expect_no_error({
    req_vsi_list <- db_vs_indexes_list(
      endpoint = "mock_endpoint",
      perform_request = FALSE
    )
  })
  expect_s3_class(req_vsi_list, "httr2_request")

  expect_no_error({
    req_vsi_get <- db_vs_indexes_get(
      index = "mock_index",
      perform_request = FALSE
    )
  })
  expect_s3_class(req_vsi_get, "httr2_request")

  expect_no_error({
    req_vsi_scan <- db_vs_indexes_scan(
      index = "mock_index",
      last_primary_key = "mock_primary_key",
      num_results = 10,
      endpoint = "mock_endpoint",
      perform_request = FALSE
    )
  })
  expect_s3_class(req_vsi_scan, "httr2_request")

  expect_no_error({
    req_vsi_delete <- db_vs_indexes_delete(
      index = "mock_index",
      perform_request = FALSE
    )
  })
  expect_s3_class(req_vsi_delete, "httr2_request")

  expect_no_error({
    req_vsi_query_next_page <- db_vs_indexes_query_next_page(
      index = "mock_index",
      endpoint = "mock_endpoint",
      page_token = "mock_page_token",
      perform_request = FALSE
    )
  })
  expect_s3_class(req_vsi_query_next_page, "httr2_request")

  expect_no_error({
    req_vsi_sync <- db_vs_indexes_sync(
      index = "mock_index",
      perform_request = FALSE
    )
  })
  expect_s3_class(req_vsi_sync, "httr2_request")

  expect_no_error({
    req_vsi_delete_data <- db_vs_indexes_delete_data(
      index = "mock_index",
      primary_keys = 1,
      perform_request = FALSE
    )
  })
  expect_s3_class(req_vsi_delete_data, "httr2_request")

  expect_no_error({
    req_vsi_upsert_data <- db_vs_indexes_upsert_data(
      index = "mock_index",
      df = tibble::tibble(a = 1, b = 2),
      perform_request = FALSE
    )
  })
  expect_s3_class(req_vsi_upsert_data, "httr2_request")

  expect_no_error({
    req_vsi_query <- db_vs_indexes_query(
      index = "mock_index",
      columns = c("mock_a", "mock_b", "mock_c"),
      filters_json = '{"mock_a <": 5}',
      query_text = "mock query text",
      num_results = 10,
      perform_request = FALSE
    )
  })
  expect_s3_class(req_vsi_query, "httr2_request")


  esc <- embedding_source_column(
    name = "mockColumnName",
    model_endpoint_name = "mockEndpointName"
  )
  evc <- embedding_vector_column(
    name = "mockColumnName",
    dimension = 256
  )

  expect_no_error({
    ds_index <- delta_sync_index_spec(
      source_table = "mock.table.name",
      embedding_writeback_table = "mock_writeback_table",
      embedding_source_columns = esc,
      embedding_vector_columns = evc,
      pipeline_type = "TRIGGERED"
    )
    req_vsi_create_ds <- db_vs_indexes_create(
      name = "mock_index",
      endpoint = "mock_endpoint",
      primary_key = "mock_pk",
      spec = ds_index,
      perform_request = FALSE
    )
  })
  expect_s3_class(req_vsi_create_ds, "httr2_request")

  expect_no_error({
    da_index <- direct_access_index_spec(
      embedding_source_columns = esc,
      embedding_vector_columns = evc,
      schema = list("mock_col_a" = "integer")
    )
    req_vsi_create_da <- db_vs_indexes_create(
      name = "mock_index",
      endpoint = "mock_endpoint",
      primary_key = "mock_pk",
      spec = da_index,
      perform_request = FALSE
    )
  })
  expect_s3_class(req_vsi_create_da, "httr2_request")

})

# skip_on_cran()
# skip_unless_authenticated()
# skip_unless_aws_workspace()
#
# test_that("Vector Search APIs", {
#
# })


