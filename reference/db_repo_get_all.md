# Get All Repos

Get All Repos

## Usage

``` r
db_repo_get_all(
  path_prefix,
  next_page_token = NULL,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

- path_prefix:

  Filters repos that have paths starting with the given path prefix.

- next_page_token:

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

Returns repos that the calling user has Manage permissions on. Results
are paginated with each page containing twenty repos.

## See also

Other Repos API:
[`db_repo_create()`](https://databrickslabs.github.io/brickster/reference/db_repo_create.md),
[`db_repo_delete()`](https://databrickslabs.github.io/brickster/reference/db_repo_delete.md),
[`db_repo_get()`](https://databrickslabs.github.io/brickster/reference/db_repo_get.md),
[`db_repo_update()`](https://databrickslabs.github.io/brickster/reference/db_repo_update.md)
