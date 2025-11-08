# Make a Directory (Workspaces)

Make a Directory (Workspaces)

## Usage

``` r
db_workspace_mkdirs(
  path,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

- path:

  Absolute path of the directory.

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

Create the given directory and necessary parent directories if they do
not exists. If there exists an object (not a directory) at any prefix of
the input path, this call returns an error `RESOURCE_ALREADY_EXISTS.` If
this operation fails it may have succeeded in creating some of the
necessary parent directories.

## See also

Other Workspace API:
[`db_workspace_delete()`](https://databrickslabs.github.io/brickster/reference/db_workspace_delete.md),
[`db_workspace_export()`](https://databrickslabs.github.io/brickster/reference/db_workspace_export.md),
[`db_workspace_get_status()`](https://databrickslabs.github.io/brickster/reference/db_workspace_get_status.md),
[`db_workspace_import()`](https://databrickslabs.github.io/brickster/reference/db_workspace_import.md),
[`db_workspace_list()`](https://databrickslabs.github.io/brickster/reference/db_workspace_list.md)
