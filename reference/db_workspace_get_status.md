# Get Object Status (Workspaces)

Gets the status of an object or a directory.

## Usage

``` r
db_workspace_get_status(
  path,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

- path:

  Absolute path of the notebook or directory.

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

If path does not exist, this call returns an error
`RESOURCE_DOES_NOT_EXIST.`

## See also

Other Workspace API:
[`db_workspace_delete()`](https://databrickslabs.github.io/brickster/reference/db_workspace_delete.md),
[`db_workspace_export()`](https://databrickslabs.github.io/brickster/reference/db_workspace_export.md),
[`db_workspace_import()`](https://databrickslabs.github.io/brickster/reference/db_workspace_import.md),
[`db_workspace_list()`](https://databrickslabs.github.io/brickster/reference/db_workspace_list.md),
[`db_workspace_mkdirs()`](https://databrickslabs.github.io/brickster/reference/db_workspace_mkdirs.md)
