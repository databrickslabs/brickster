# https://docs.databricks.com/dev-tools/api/latest/secrets.html

#' Create Secret Scope
#'
#' @param scope Scope name requested by the user. Scope names are unique.
#' @param initial_manage_principal The principal that is initially granted
#' `MANAGE` permission to the created scope.
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' Create a Databricks-backed secret scope in which secrets are stored in
#' Databricks-managed storage and encrypted with a cloud-based specific
#' encryption key.
#'
#' The scope name:
#' *  Must be unique within a workspace.
#' *  Must consist of alphanumeric characters, dashes, underscores, and periods,
#' and may not exceed 128 characters.
#'
#' The names are considered non-sensitive and are readable by all users in the
#' workspace. A workspace is limited to a maximum of 100 secret scopes.
#'
#' If `initial_manage_principal` is specified, the initial ACL applied to the
#' scope is applied to the supplied principal (user or group) with `MANAGE`
#' permissions. The only supported principal for this option is the group users,
#' which contains all users in the workspace. If `initial_manage_principal` is
#' not specified, the initial ACL with `MANAGE` permission applied to the scope
#' is assigned to the API request issuer’s user identity.
#'
#' * Throws `RESOURCE_ALREADY_EXISTS` if a scope with the given name already
#' exists.
#' * Throws `RESOURCE_LIMIT_EXCEEDED` if maximum number of scopes in the
#' workspace is exceeded.
#' * Throws `INVALID_PARAMETER_VALUE` if the scope name is invalid.
#'
#' @family Secrets API
#'
#' @export
db_secrets_scope_create <- function(scope, initial_manage_principal = NULL,
                                    host = db_host(), token = db_token(),
                                    perform_request = TRUE) {
  body <- list(
    scope = scope,
    initial_manage_principal = initial_manage_principal
  )

  req <- db_request(
    endpoint = "secrets/scopes/create",
    method = "POST",
    version = "2.0",
    body = body,
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }

}

#' Delete Secret Scope
#'
#' @param scope Name of the scope to delete.
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' * Throws `RESOURCE_DOES_NOT_EXIST` if the scope does not exist.
#' * Throws `PERMISSION_DENIED` if the user does not have permission to make
#' this API call.
#'
#' @family Secrets API
#'
#' @export
db_secrets_scope_delete <- function(scope,
                                    host = db_host(), token = db_token(),
                                    perform_request = TRUE) {
  body <- list(
    scope = scope
  )

  req <- db_request(
    endpoint = "secrets/scopes/delete",
    method = "POST",
    version = "2.0",
    body = body,
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }

}

#' List Secret Scopes
#'
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' * Throws `PERMISSION_DENIED` if you do not have permission to make this API
#' call.
#'
#' @family Secrets API
#'
#' @export
db_secrets_scope_list_all <- function(host = db_host(), token = db_token(),
                                      perform_request = TRUE) {
  req <- db_request(
    endpoint = "secrets/scopes/list",
    method = "GET",
    version = "2.0",
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }

}

#' Put Secret in Secret Scope
#'
#' Insert a secret under the provided scope with the given name.
#'
#' @param scope Name of the scope to which the secret will be associated with
#' @param key Unique name to identify the secret.
#' @param value Contents of the secret to store, must be a string.
#' @param as_bytes Boolean (default: `FALSE`). Determines if `value` is stored
#' as bytes.
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' If a secret already exists with the same name, this command overwrites the
#' existing secret’s value.
#'
#' The server encrypts the secret using the secret scope’s encryption settings
#' before storing it. You must have `WRITE` or `MANAGE` permission on the secret
#' scope.
#'
#' The secret key must consist of alphanumeric characters, dashes, underscores,
#' and periods, and cannot exceed 128 characters. The maximum allowed secret
#' value size is 128 KB. The maximum number of secrets in a given scope is 1000.
#'
#' You can read a secret value only from within a command on a cluster
#' (for example, through a notebook); there is no API to read a secret value
#' outside of a cluster. The permission applied is based on who is invoking the
#' command and you must have at least `READ` permission.
#'
#' The input fields `string_value` or `bytes_value` specify the type of the
#' secret, which will determine the value returned when the secret value is
#' requested. Exactly one must be specified, this function interfaces these
#' parameters via `as_bytes` which defaults to `FALSE`.
#'
#' * Throws `RESOURCE_DOES_NOT_EXIST` if no such secret scope exists.
#' * Throws `RESOURCE_LIMIT_EXCEEDED` if maximum number of secrets in scope is
#' exceeded.
#' * Throws `INVALID_PARAMETER_VALUE` if the key name or value length is
#' invalid.
#' * Throws `PERMISSION_DENIED` if the user does not have permission to make
#' this API call.
#'
#' @family Secrets API
#'
#' @export
db_secrets_put <- function(scope, key, value, as_bytes = FALSE,
                           host = db_host(), token = db_token(),
                           perform_request = TRUE) {
  body <- list(
    scope = scope,
    key = key
  )

  if (as_bytes) {
    body[["bytes_value"]] <- charToRaw(value)
  } else {
    body[["string_value"]] <- value
  }

  req <- db_request(
    endpoint = "secrets/put",
    method = "POST",
    version = "2.0",
    body = body,
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }

}

#' Delete Secret in Secret Scope
#'
#' @param scope Name of the scope that contains the secret to delete.
#' @param key Name of the secret to delete.
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' You must have `WRITE` or `MANAGE` permission on the secret scope.
#'
#' * Throws `RESOURCE_DOES_NOT_EXIST` if no such secret scope or secret exists.
#' * Throws `PERMISSION_DENIED` if you do not have permission to make this API
#' call.
#'
#' @family Secrets API
#'
#' @export
db_secrets_delete <- function(scope, key,
                              host = db_host(), token = db_token(),
                              perform_request = TRUE) {
  body <- list(
    scope = scope,
    key = key
  )

  req <- db_request(
    endpoint = "secrets/delete",
    method = "POST",
    version = "2.0",
    body = body,
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }

}

#' List Secrets in Secret Scope
#'
#' @param scope Name of the scope whose secrets you want to list
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' This is a metadata-only operation; you cannot retrieve secret data using this
#' API. You must have `READ` permission to make this call.
#'
#' The `last_updated_timestamp` returned is in milliseconds since epoch.
#'
#' * Throws `RESOURCE_DOES_NOT_EXIST` if no such secret scope exists.
#' * Throws `PERMISSION_DENIED` if you do not have permission to make this API
#' call.
#'
#' @family Secrets API
#'
#' @export
db_secrets_list <- function(scope,
                            host = db_host(), token = db_token(),
                            perform_request = TRUE) {
  body <- list(
    scope = scope
  )

  req <- db_request(
    endpoint = "secrets/list",
    method = "GET",
    version = "2.0",
    body = body,
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }

}

#' Put ACL on Secret Scope
#'
#' @param scope Name of the scope to apply permissions.
#' @param principal Principal to which the permission is applied
#' @param permission Permission level applied to the principal. One of `READ`,
#' `WRITE`, `MANAGE`.
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' Create or overwrite the ACL associated with the given principal (user or
#' group) on the specified scope point. In general, a user or group will use
#' the most powerful permission available to them, and permissions are ordered
#' as follows:
#'
#' * `MANAGE` - Allowed to change ACLs, and read and write to this secret scope.
#' * `WRITE` - Allowed to read and write to this secret scope.
#' * `READ` - Allowed to read this secret scope and list what secrets are
#' available.
#'
#' You must have the `MANAGE` permission to invoke this API.
#'
#' The principal is a user or group name corresponding to an existing Databricks
#' principal to be granted or revoked access.
#'
#' * Throws `RESOURCE_DOES_NOT_EXIST` if no such secret scope exists.
#' * Throws `RESOURCE_ALREADY_EXISTS` if a permission for the principal already
#' exists.
#' * Throws `INVALID_PARAMETER_VALUE` if the permission is invalid.
#' * Throws `PERMISSION_DENIED` if you do not have permission to make this API
#' call.
#'
#' @family Secrets API
#'
#' @export
db_secrets_scope_acl_put <- function(scope, principal,
                                     permission = c("READ", "WRITE", "MANAGE"),
                                     host = db_host(),
                                     token = db_token(),
                                     perform_request = TRUE) {
  permission <- match.arg(permission, several.ok = FALSE)

  body <- list(
    scope = scope,
    principal = principal,
    permission = permission
  )

  req <- db_request(
    endpoint = "secrets/acls/put",
    method = "POST",
    version = "2.0",
    body = body,
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }

}

#' Delete Secret Scope ACL
#'
#' Delete the given ACL on the given scope.
#'
#' @param scope Name of the scope to remove permissions.
#' @param principal Principal to remove an existing ACL.
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' You must have the `MANAGE` permission to invoke this API.
#'
#' * Throws `RESOURCE_DOES_NOT_EXIST` if no such secret scope, principal, or
#' ACL exists.
#' * Throws `PERMISSION_DENIED` if you do not have permission to make this API
#' call.
#'
#' @family Secrets API
#'
#' @export
db_secrets_scope_acl_delete <- function(scope, principal,
                                        host = db_host(), token = db_token(),
                                        perform_request = TRUE) {
  body <- list(
    scope = scope,
    principal = principal
  )

  req <- db_request(
    endpoint = "secrets/acls/delete",
    method = "POST",
    version = "2.0",
    body = body,
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }

}

#' Get Secret Scope ACL
#'
#' @param scope Name of the scope to fetch ACL information from.
#' @param principal Principal to fetch ACL information from.
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' You must have the `MANAGE` permission to invoke this
#'
#' * Throws `RESOURCE_DOES_NOT_EXIST` if no such secret scope exists.
#' * Throws `PERMISSION_DENIED` if you do not have permission to make this API
#' call.
#'
#' @family Secrets API
#'
#' @export
db_secrets_scope_acl_get <- function(scope, principal,
                                     host = db_host(), token = db_token(),
                                     perform_request = TRUE) {
  body <- list(
    scope = scope,
    principal = principal
  )

  req <- db_request(
    endpoint = "secrets/acls/get",
    method = "GET",
    version = "2.0",
    body = body,
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }

}


#' List Secret Scope ACL's
#'
#' @param scope Name of the scope to fetch ACL information from.
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' You must have the `MANAGE` permission to invoke this API.
#'
#' * Throws `RESOURCE_DOES_NOT_EXIST` if no such secret scope exists.
#' * Throws `PERMISSION_DENIED` if you do not have permission to make this API
#' call.
#'
#' @family Secrets API
#'
#' @export
db_secrets_scope_acl_list <- function(scope,
                                      host = db_host(), token = db_token(),
                                      perform_request = TRUE) {
  body <- list(
    scope = scope
  )

  req <- db_request(
    endpoint = "secrets/acls/list",
    method = "GET",
    version = "2.0",
    body = body,
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }

}
