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

skip_unless_credentials_set() {
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
