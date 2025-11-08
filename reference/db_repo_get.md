# Get Repo

Returns the repo with the given repo ID.

## Usage

``` r
db_repo_get(
  repo_id,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

- repo_id:

  The ID for the corresponding repo to access.

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

Other Repos API:
[`db_repo_create()`](https://databrickslabs.github.io/brickster/reference/db_repo_create.md),
[`db_repo_delete()`](https://databrickslabs.github.io/brickster/reference/db_repo_delete.md),
[`db_repo_get_all()`](https://databrickslabs.github.io/brickster/reference/db_repo_get_all.md),
[`db_repo_update()`](https://databrickslabs.github.io/brickster/reference/db_repo_update.md)
