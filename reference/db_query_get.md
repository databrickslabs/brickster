# Get a SQL Query

Returns the repo with the given repo ID.

## Usage

``` r
db_query_get(id, host = db_host(), token = db_token(), perform_request = TRUE)
```

## Arguments

- id:

  String, ID for the query.

- host:

  Databricks workspace URL, defaults to calling
  [`db_host()`](https://databrickslabs.github.io/brickster/reference/db_host.md).

- token:

  Databricks workspace token, defaults to calling
  [`db_token()`](https://databrickslabs.github.io/brickster/reference/db_token.md).

- perform_request:

  If `TRUE` (default) the request is performed, if `FALSE` the httr2
  request is returned *without* being performed.

## See also

Other SQL Queries API:
[`db_query_create()`](https://databrickslabs.github.io/brickster/reference/db_query_create.md),
[`db_query_delete()`](https://databrickslabs.github.io/brickster/reference/db_query_delete.md),
[`db_query_list()`](https://databrickslabs.github.io/brickster/reference/db_query_list.md),
[`db_query_update()`](https://databrickslabs.github.io/brickster/reference/db_query_update.md)
