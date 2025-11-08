# Create Repo

Creates a repo in the workspace and links it to the remote Git repo
specified.

## Usage

``` r
db_repo_create(
  url,
  provider,
  path,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

- url:

  URL of the Git repository to be linked.

- provider:

  Git provider. This field is case-insensitive. The available Git
  providers are `gitHub`, `bitbucketCloud`, `gitLab`,
  `azureDevOpsServices`, `gitHubEnterprise`, `bitbucketServer` and
  `gitLabEnterpriseEdition.`

- path:

  Desired path for the repo in the workspace. Must be in the format
  `/Repos/{folder}/{repo-name}`.

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
[`db_repo_delete()`](https://databrickslabs.github.io/brickster/reference/db_repo_delete.md),
[`db_repo_get()`](https://databrickslabs.github.io/brickster/reference/db_repo_get.md),
[`db_repo_get_all()`](https://databrickslabs.github.io/brickster/reference/db_repo_get_all.md),
[`db_repo_update()`](https://databrickslabs.github.io/brickster/reference/db_repo_update.md)
