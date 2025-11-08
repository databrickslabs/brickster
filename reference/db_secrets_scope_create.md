# Create Secret Scope

Create Secret Scope

## Usage

``` r
db_secrets_scope_create(
  scope,
  initial_manage_principal = NULL,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

- scope:

  Scope name requested by the user. Scope names are unique.

- initial_manage_principal:

  The principal that is initially granted `MANAGE` permission to the
  created scope.

- host:

  Databricks workspace URL, defaults to calling
  [`db_host()`](https://databrickslabs.github.io/brickster/reference/db_host.md).

- token:

  Databricks workspace token, defaults to calling
  [`db_token()`](https://databrickslabs.github.io/brickster/reference/db_token.md).

- perform_request:

  If `TRUE` (default) the request is performed, if `FALSE` the httr2
  request is returned *without* being performed.

## Details

Create a Databricks-backed secret scope in which secrets are stored in
Databricks-managed storage and encrypted with a cloud-based specific
encryption key.

The scope name:

- Must be unique within a workspace.

- Must consist of alphanumeric characters, dashes, underscores, and
  periods, and may not exceed 128 characters.

The names are considered non-sensitive and are readable by all users in
the workspace. A workspace is limited to a maximum of 100 secret scopes.

If `initial_manage_principal` is specified, the initial ACL applied to
the scope is applied to the supplied principal (user or group) with
`MANAGE` permissions. The only supported principal for this option is
the group users, which contains all users in the workspace. If
`initial_manage_principal` is not specified, the initial ACL with
`MANAGE` permission applied to the scope is assigned to the API request
issuer’s user identity.

- Throws `RESOURCE_ALREADY_EXISTS` if a scope with the given name
  already exists.

- Throws `RESOURCE_LIMIT_EXCEEDED` if maximum number of scopes in the
  workspace is exceeded.

- Throws `INVALID_PARAMETER_VALUE` if the scope name is invalid.

## See also

Other Secrets API:
[`db_secrets_delete()`](https://databrickslabs.github.io/brickster/reference/db_secrets_delete.md),
[`db_secrets_list()`](https://databrickslabs.github.io/brickster/reference/db_secrets_list.md),
[`db_secrets_put()`](https://databrickslabs.github.io/brickster/reference/db_secrets_put.md),
[`db_secrets_scope_acl_delete()`](https://databrickslabs.github.io/brickster/reference/db_secrets_scope_acl_delete.md),
[`db_secrets_scope_acl_get()`](https://databrickslabs.github.io/brickster/reference/db_secrets_scope_acl_get.md),
[`db_secrets_scope_acl_list()`](https://databrickslabs.github.io/brickster/reference/db_secrets_scope_acl_list.md),
[`db_secrets_scope_acl_put()`](https://databrickslabs.github.io/brickster/reference/db_secrets_scope_acl_put.md),
[`db_secrets_scope_delete()`](https://databrickslabs.github.io/brickster/reference/db_secrets_scope_delete.md),
[`db_secrets_scope_list_all()`](https://databrickslabs.github.io/brickster/reference/db_secrets_scope_list_all.md)
