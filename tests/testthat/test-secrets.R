test_that("Secrets API", {

  # if scope exists, delete
  scope_exists <- "brickster_test_scope" %in%
    purrr::map_chr(db_secrets_scope_list_all()$scopes, "name")
  if (scope_exists) {
    db_secrets_scope_delete(scope = "brickster_test_scope")
  }

  expect_no_error({
    resp_scope_create <- db_secrets_scope_create(
      scope = "brickster_test_scope"
    )
  })
  expect_type(resp_scope_create, "list")

  expect_no_error({
    resp_list <- db_secrets_list(scope = "brickster_test_scope")
  })
  expect_type(resp_list, "list")

  expect_no_error({
    resp_scope_acl_list <- db_secrets_scope_acl_list(
      scope = "brickster_test_scope"
    )
  })
  expect_type(resp_scope_acl_list, "list")

  expect_no_error({
    resp_scope_acl_get <- db_secrets_scope_acl_get(
      scope = "brickster_test_scope",
      principal = resp_scope_acl_list$items[[1]]$principal
    )
  })
  expect_type(resp_scope_acl_get, "list")
  expect_identical(resp_scope_acl_get$permission, "MANAGE")

  expect_no_error({
    resp_scope_list_all <- db_secrets_scope_list_all()
  })
  expect_type(resp_scope_list_all, "list")
  expect_true(
    "brickster_test_scope" %in%
      purrr::map_chr(resp_scope_list_all$scopes, "name")
  )

  expect_no_error({
    resp_put <- db_secrets_put(
      scope = "brickster_test_scope",
      key = "some_key",
      value = "some_value"
    )
  })
  expect_type(resp_put, "list")

  expect_no_error({
    resp_delete <- db_secrets_delete(
      scope = "brickster_test_scope",
      key = "some_key"
    )
  })
  expect_type(resp_delete, "list")

  expect_no_error({
    resp_scope_delete <- db_secrets_scope_delete(
      scope = "brickster_test_scope"
    )
  })
  expect_type(resp_scope_delete, "list")

})



test_that("Secrets API - don't perform", {

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
