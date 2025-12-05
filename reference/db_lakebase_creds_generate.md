# Generate Database Credential

Generate Database Credential

## Usage

``` r
db_lakebase_creds_generate(
  instance_names,
  tables = NULL,
  permission_set = c("READ_ONLY"),
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

- instance_names:

  Character vector of database instance names to scope the credential
  to.

- tables:

  Optional character vector of table names to scope the credential to.

- permission_set:

  Permission set for the credential request. Currently only `READ_ONLY`
  is supported.

- host:

  Databricks workspace URL, defaults to calling
  [`db_host()`](https://databrickslabs.github.io/brickster/reference/db_host.md).

- token:

  Databricks workspace token, defaults to calling
  [`db_token()`](https://databrickslabs.github.io/brickster/reference/db_token.md).

- perform_request:

  If `TRUE` (default) the request is performed, if `FALSE` the httr2
  request is returned *without* being performed.

## Value

List

## Details

An idempotency token is generated automatically for each request
(UUID4-like string).

## See also

Other Database API:
[`db_lakebase_get()`](https://databrickslabs.github.io/brickster/reference/db_lakebase_get.md),
[`db_lakebase_get_by_uid()`](https://databrickslabs.github.io/brickster/reference/db_lakebase_get_by_uid.md),
[`db_lakebase_list()`](https://databrickslabs.github.io/brickster/reference/db_lakebase_list.md)
