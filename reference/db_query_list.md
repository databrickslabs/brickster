# List SQL Queries

List SQL Queries

## Usage

``` r
db_query_list(
  page_size = 20,
  page_token = NULL,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

- page_size:

  Integer, number of results to return for each request.

- page_token:

  Token used to get the next page of results. If not specified, returns
  the first page of results as well as a next page token if there are
  more results.

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

Gets a list of queries accessible to the user, ordered by creation time.
Warning: Calling this API concurrently 10 or more times could result in
throttling, service degradation, or a temporary ban.

## See also

Other SQL Queries API:
[`db_query_create()`](https://databrickslabs.github.io/brickster/reference/db_query_create.md),
[`db_query_delete()`](https://databrickslabs.github.io/brickster/reference/db_query_delete.md),
[`db_query_get()`](https://databrickslabs.github.io/brickster/reference/db_query_get.md),
[`db_query_update()`](https://databrickslabs.github.io/brickster/reference/db_query_update.md)
