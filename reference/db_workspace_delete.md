# Delete Object/Directory (Workspaces)

Delete Object/Directory (Workspaces)

## Usage

``` r
db_workspace_delete(
  path,
  recursive = FALSE,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

- path:

  Absolute path of the notebook or directory.

- recursive:

  Flag that specifies whether to delete the object recursively. `False`
  by default.

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

Delete an object or a directory (and optionally recursively deletes all
objects in the directory). If path does not exist, this call returns an
error `RESOURCE_DOES_NOT_EXIST`. If path is a non-empty directory and
recursive is set to false, this call returns an error
`DIRECTORY_NOT_EMPTY.`

Object deletion cannot be undone and deleting a directory recursively is
not atomic.

## See also

Other Workspace API:
[`db_workspace_export()`](https://databrickslabs.github.io/brickster/reference/db_workspace_export.md),
[`db_workspace_get_status()`](https://databrickslabs.github.io/brickster/reference/db_workspace_get_status.md),
[`db_workspace_import()`](https://databrickslabs.github.io/brickster/reference/db_workspace_import.md),
[`db_workspace_list()`](https://databrickslabs.github.io/brickster/reference/db_workspace_list.md),
[`db_workspace_mkdirs()`](https://databrickslabs.github.io/brickster/reference/db_workspace_mkdirs.md)
