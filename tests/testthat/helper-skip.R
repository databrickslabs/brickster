skip_unless_aws_workspace <- function() {
  if (db_current_cloud() != "aws") {
    skip("Test only runs on Databricks workspaces in AWS")
  }
}


skip_unless_authenticated <- function() {
  authenticated <- tryCatch(
    {
      current_user <- db_current_user()
      TRUE
    },
    error = function(cond) {
      FALSE
    }
  )

  if (!authenticated) {
    skip("Test only runs when connection to a workspace is established")
  }
}

skip_unless_credentials_set <- function() {
  creds_avialable <- tryCatch(
    {
      db_host()
      db_token()
      TRUE
    },
    error = function(cond) {
      FALSE
    }
  )

  if (!creds_avialable) {
    skip("Test only runs when credentials are available")
  }
}

skip_unless_warehouse_available <- function() {
  skip_unless_authenticated()

  warehouse_id <- Sys.getenv("DATABRICKS_WAREHOUSE_ID")
  if (!nzchar(warehouse_id)) {
    skip("Test only runs when DATABRICKS_WAREHOUSE_ID is available")
  }
}

# Warehouse test helpers
create_test_warehouse <- function() {
  # Generate unique name for test warehouse
  random_id <- sample.int(100000, 1)
  warehouse_name <- paste0("brickster_tests_", random_id)

  # Create serverless warehouse (fastest startup)
  warehouse_resp <- db_sql_warehouse_create(
    name = warehouse_name,
    cluster_size = "2X-Small",
    min_num_clusters = 1,
    max_num_clusters = 1,
    auto_stop_mins = 10, # Serverless warehouses should use 10 minutes
    enable_serverless_compute = TRUE,
    enable_photon = TRUE,
    tags = list(purpose = "brickster_testing")
  )

  # Wait for warehouse to be ready
  warehouse_id <- warehouse_resp$id
  get_and_start_warehouse(warehouse_id)

  return(warehouse_id)
}

cleanup_test_warehouse <- function(warehouse_id) {
  if (!is.null(warehouse_id) && nzchar(warehouse_id)) {
    tryCatch(
      {
        db_sql_warehouse_delete(warehouse_id)
      },
      error = function(e) {
        # Ignore cleanup errors to avoid masking test failures
        message("Failed to cleanup warehouse: ", warehouse_id, " - ", e$message)
      }
    )
  }
}
