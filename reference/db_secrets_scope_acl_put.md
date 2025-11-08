# Put ACL on Secret Scope

Put ACL on Secret Scope

## Usage

``` r
db_secrets_scope_acl_put(
  scope,
  principal,
  permission = c("READ", "WRITE", "MANAGE"),
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

- scope:

  Name of the scope to apply permissions.

- principal:

  Principal to which the permission is applied

- permission:

  Permission level applied to the principal. One of `READ`, `WRITE`,
  `MANAGE`.

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

Create or overwrite the ACL associated with the given principal (user or
group) on the specified scope point. In general, a user or group will
use the most powerful permission available to them, and permissions are
ordered as follows:

- `MANAGE` - Allowed to change ACLs, and read and write to this secret
  scope.

- `WRITE` - Allowed to read and write to this secret scope.

- `READ` - Allowed to read this secret scope and list what secrets are
  available.

You must have the `MANAGE` permission to invoke this API.

The principal is a user or group name corresponding to an existing
Databricks principal to be granted or revoked access.

- Throws `RESOURCE_DOES_NOT_EXIST` if no such secret scope exists.

- Throws `RESOURCE_ALREADY_EXISTS` if a permission for the principal
  already exists.

- Throws `INVALID_PARAMETER_VALUE` if the permission is invalid.

- Throws `PERMISSION_DENIED` if you do not have permission to make this
  API call.

## See also

Other Secrets API:
[`db_secrets_delete()`](https://databrickslabs.github.io/brickster/reference/db_secrets_delete.md),
[`db_secrets_list()`](https://databrickslabs.github.io/brickster/reference/db_secrets_list.md),
[`db_secrets_put()`](https://databrickslabs.github.io/brickster/reference/db_secrets_put.md),
[`db_secrets_scope_acl_delete()`](https://databrickslabs.github.io/brickster/reference/db_secrets_scope_acl_delete.md),
[`db_secrets_scope_acl_get()`](https://databrickslabs.github.io/brickster/reference/db_secrets_scope_acl_get.md),
[`db_secrets_scope_acl_list()`](https://databrickslabs.github.io/brickster/reference/db_secrets_scope_acl_list.md),
[`db_secrets_scope_create()`](https://databrickslabs.github.io/brickster/reference/db_secrets_scope_create.md),
[`db_secrets_scope_delete()`](https://databrickslabs.github.io/brickster/reference/db_secrets_scope_delete.md),
[`db_secrets_scope_list_all()`](https://databrickslabs.github.io/brickster/reference/db_secrets_scope_list_all.md)
