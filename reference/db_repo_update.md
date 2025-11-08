# Update Repo

Updates the repo to the given branch or tag.

## Usage

``` r
db_repo_update(
  repo_id,
  branch = NULL,
  tag = NULL,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

- repo_id:

  The ID for the corresponding repo to access.

- branch:

  Branch that the local version of the repo is checked out to.

- tag:

  Tag that the local version of the repo is checked out to.

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

Specify either `branch` or `tag`, not both.

Updating the repo to a tag puts the repo in a detached HEAD state.
Before committing new changes, you must update the repo to a branch
instead of the detached HEAD.

## See also

Other Repos API:
[`db_repo_create()`](https://databrickslabs.github.io/brickster/reference/db_repo_create.md),
[`db_repo_delete()`](https://databrickslabs.github.io/brickster/reference/db_repo_delete.md),
[`db_repo_get()`](https://databrickslabs.github.io/brickster/reference/db_repo_get.md),
[`db_repo_get_all()`](https://databrickslabs.github.io/brickster/reference/db_repo_get_all.md)
