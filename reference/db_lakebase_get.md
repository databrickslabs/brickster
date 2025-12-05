# Get Database Instance

Get Database Instance

## Usage

``` r
db_lakebase_get(
  name,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

- name:

  Name of the database instance to retrieve.

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

## See also

Other Database API:
[`db_lakebase_creds_generate()`](https://databrickslabs.github.io/brickster/reference/db_lakebase_creds_generate.md),
[`db_lakebase_get_by_uid()`](https://databrickslabs.github.io/brickster/reference/db_lakebase_get_by_uid.md),
[`db_lakebase_list()`](https://databrickslabs.github.io/brickster/reference/db_lakebase_list.md)
