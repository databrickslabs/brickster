test_that("Secrets API - don't perform", {

  withr::local_envvar(c(
    "DATABRICKS_HOST" = "http://mock_host",
    "DATABRICKS_TOKEN" = "mock_token"
  ))

  resp_list <- db_secrets_list(
    scope = "some_scope",
    perform_request = FALSE
  )
  expect_s3_class(resp_list, "httr2_request")

  resp_list_all <- db_secrets_scope_list_all(
    perform_request = FALSE
  )
  expect_s3_class(resp_list_all, "httr2_request")

  resp_delete <- db_secrets_delete(
    scope = "some_scope",
    key = "some_key",
    perform_request = F
  )
  expect_s3_class(resp_delete, "httr2_request")

  resp_put <- db_secrets_put(
    scope = "some_scope",
    key = "some_key",
    value = "some_value",
    perform_request = F
  )
  expect_s3_class(resp_put, "httr2_request")

  resp_acl_del <- db_secrets_scope_acl_delete(
    scope = "some_scope",
    principal = "some_principal",
    perform_request = F
  )
  expect_s3_class(resp_acl_del, "httr2_request")

  resp_acl_get <- db_secrets_scope_acl_get(
    scope = "some_scope",
    principal = "some_principal",
    perform_request = F
  )
  expect_s3_class(resp_acl_get, "httr2_request")

  resp_acl_list <- db_secrets_scope_acl_list(
    scope = "some_scope",
    perform_request = F
  )
  expect_s3_class(resp_acl_list, "httr2_request")

  resp_acl_put <- db_secrets_scope_acl_put(
    scope = "some_scope",
    principal = "some_principal",
    permission = "READ",
    perform_request = F
  )
  expect_s3_class(resp_acl_put, "httr2_request")

  resp_scope_create <- db_secrets_scope_create(
    scope = "some_scope",
    perform_request = F
  )
  expect_s3_class(resp_scope_create, "httr2_request")

  resp_scope_del <- db_secrets_scope_delete(
    scope = "some_scope",
    perform_request = F
  )
  expect_s3_class(resp_scope_del, "httr2_request")

  resp_scope_list_all <- db_secrets_scope_list_all(perform_request = F)
  expect_s3_class(resp_scope_list_all, "httr2_request")

})

skip_on_cran()
skip_unless_authenticated()
skip_unless_aws_workspace()

# NOTE: test environment has no room left for secrets, removing tests temporarily
# test_that("Secrets API", {
#
#   scope_id <- sample.int(100000, 1)
#   scope_name <- paste0("brickster_test_scope_", scope_id)
#
#   # if scope exists, delete
#   scope_exists <- scope_name %in%
#     purrr::map_chr(db_secrets_scope_list_all()$scopes, "name")
#   if (scope_exists) {
#     db_secrets_scope_delete(scope = scope_name)
#   }
#
#   expect_no_error({
#     resp_scope_create <- db_secrets_scope_create(
#       scope = scope_name
#     )
#   })
#   expect_type(resp_scope_create, "list")
#
#   expect_no_error({
#     resp_list <- db_secrets_list(scope = scope_name)
#   })
#   expect_type(resp_list, "list")
#
#   expect_no_error({
#     resp_scope_acl_list <- db_secrets_scope_acl_list(
#       scope = scope_name
#     )
#   })
#   expect_type(resp_scope_acl_list, "list")
#
#   expect_no_error({
#     resp_scope_acl_get <- db_secrets_scope_acl_get(
#       scope = scope_name,
#       principal = resp_scope_acl_list$items[[1]]$principal
#     )
#   })
#   expect_type(resp_scope_acl_get, "list")
#   expect_identical(resp_scope_acl_get$permission, "MANAGE")
#
#   expect_no_error({
#     resp_scope_list_all <- db_secrets_scope_list_all()
#   })
#   expect_type(resp_scope_list_all, "list")
#   expect_true(
#     scope_name %in%
#       purrr::map_chr(resp_scope_list_all$scopes, "name")
#   )
#
#   expect_no_error({
#     resp_put <- db_secrets_put(
#       scope = scope_name,
#       key = "some_key",
#       value = "some_value"
#     )
#   })
#   expect_type(resp_put, "list")
#
#   expect_no_error({
#     resp_delete <- db_secrets_delete(
#       scope = scope_name,
#       key = "some_key"
#     )
#   })
#   expect_type(resp_delete, "list")
#
#   expect_no_error({
#     resp_scope_delete <- db_secrets_scope_delete(
#       scope = scope_name
#     )
#   })
#   expect_type(resp_scope_delete, "list")
#
# })
