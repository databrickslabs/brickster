# Put Secret in Secret Scope

Insert a secret under the provided scope with the given name.

## Usage

``` r
db_secrets_put(
  scope,
  key,
  value,
  as_bytes = FALSE,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

- scope:

  Name of the scope to which the secret will be associated with

- key:

  Unique name to identify the secret.

- value:

  Contents of the secret to store, must be a string.

- as_bytes:

  Boolean (default: `FALSE`). Determines if `value` is stored as bytes.

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

If a secret already exists with the same name, this command overwrites
the existing secret’s value.

The server encrypts the secret using the secret scope’s encryption
settings before storing it. You must have `WRITE` or `MANAGE` permission
on the secret scope.

The secret key must consist of alphanumeric characters, dashes,
underscores, and periods, and cannot exceed 128 characters. The maximum
allowed secret value size is 128 KB. The maximum number of secrets in a
given scope is 1000.

You can read a secret value only from within a command on a cluster (for
example, through a notebook); there is no API to read a secret value
outside of a cluster. The permission applied is based on who is invoking
the command and you must have at least `READ` permission.

The input fields `string_value` or `bytes_value` specify the type of the
secret, which will determine the value returned when the secret value is
requested. Exactly one must be specified, this function interfaces these
parameters via `as_bytes` which defaults to `FALSE`.

- Throws `RESOURCE_DOES_NOT_EXIST` if no such secret scope exists.

- Throws `RESOURCE_LIMIT_EXCEEDED` if maximum number of secrets in scope
  is exceeded.

- Throws `INVALID_PARAMETER_VALUE` if the key name or value length is
  invalid.

- Throws `PERMISSION_DENIED` if the user does not have permission to
  make this API call.

## See also

Other Secrets API:
[`db_secrets_delete()`](https://databrickslabs.github.io/brickster/reference/db_secrets_delete.md),
[`db_secrets_list()`](https://databrickslabs.github.io/brickster/reference/db_secrets_list.md),
[`db_secrets_scope_acl_delete()`](https://databrickslabs.github.io/brickster/reference/db_secrets_scope_acl_delete.md),
[`db_secrets_scope_acl_get()`](https://databrickslabs.github.io/brickster/reference/db_secrets_scope_acl_get.md),
[`db_secrets_scope_acl_list()`](https://databrickslabs.github.io/brickster/reference/db_secrets_scope_acl_list.md),
[`db_secrets_scope_acl_put()`](https://databrickslabs.github.io/brickster/reference/db_secrets_scope_acl_put.md),
[`db_secrets_scope_create()`](https://databrickslabs.github.io/brickster/reference/db_secrets_scope_create.md),
[`db_secrets_scope_delete()`](https://databrickslabs.github.io/brickster/reference/db_secrets_scope_delete.md),
[`db_secrets_scope_list_all()`](https://databrickslabs.github.io/brickster/reference/db_secrets_scope_list_all.md)
