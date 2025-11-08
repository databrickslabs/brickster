# List Secrets in Secret Scope

List Secrets in Secret Scope

## Usage

``` r
db_secrets_list(
  scope,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

- scope:

  Name of the scope whose secrets you want to list

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

This is a metadata-only operation; you cannot retrieve secret data using
this API. You must have `READ` permission to make this call.

The `last_updated_timestamp` returned is in milliseconds since epoch.

- Throws `RESOURCE_DOES_NOT_EXIST` if no such secret scope exists.

- Throws `PERMISSION_DENIED` if you do not have permission to make this
  API call.

## See also

Other Secrets API:
[`db_secrets_delete()`](https://databrickslabs.github.io/brickster/reference/db_secrets_delete.md),
[`db_secrets_put()`](https://databrickslabs.github.io/brickster/reference/db_secrets_put.md),
[`db_secrets_scope_acl_delete()`](https://databrickslabs.github.io/brickster/reference/db_secrets_scope_acl_delete.md),
[`db_secrets_scope_acl_get()`](https://databrickslabs.github.io/brickster/reference/db_secrets_scope_acl_get.md),
[`db_secrets_scope_acl_list()`](https://databrickslabs.github.io/brickster/reference/db_secrets_scope_acl_list.md),
[`db_secrets_scope_acl_put()`](https://databrickslabs.github.io/brickster/reference/db_secrets_scope_acl_put.md),
[`db_secrets_scope_create()`](https://databrickslabs.github.io/brickster/reference/db_secrets_scope_create.md),
[`db_secrets_scope_delete()`](https://databrickslabs.github.io/brickster/reference/db_secrets_scope_delete.md),
[`db_secrets_scope_list_all()`](https://databrickslabs.github.io/brickster/reference/db_secrets_scope_list_all.md)
