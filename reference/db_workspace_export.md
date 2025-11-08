# Export Notebook or Directory (Workspaces)

Export Notebook or Directory (Workspaces)

## Usage

``` r
db_workspace_export(
  path,
  format = c("AUTO", "SOURCE", "HTML", "JUPYTER", "DBC", "R_MARKDOWN"),
  host = db_host(),
  token = db_token(),
  output_path = NULL,
  direct_download = FALSE,
  perform_request = TRUE
)
```

## Arguments

- path:

  Absolute path of the notebook or directory.

- format:

  One of `AUTO`, `SOURCE`, `HTML`, `JUPYTER`, `DBC`, `R_MARKDOWN`.
  Default is `SOURCE`.

- host:

  Databricks workspace URL, defaults to calling
  [`db_host()`](https://databrickslabs.github.io/brickster/reference/db_host.md).

- token:

  Databricks workspace token, defaults to calling
  [`db_token()`](https://databrickslabs.github.io/brickster/reference/db_token.md).

- output_path:

  Path to export file to, ensure to include correct suffix.

- direct_download:

  Boolean (default: `FALSE`), if `TRUE` download file contents directly
  to file. Must also specify `output_path`.

- perform_request:

  If `TRUE` (default) the request is performed, if `FALSE` the httr2
  request is returned *without* being performed.

## Value

base64 encoded string

## Details

Export a notebook or contents of an entire directory. If path does not
exist, this call returns an error `RESOURCE_DOES_NOT_EXIST.`

You can export a directory only in `DBC` format. If the exported data
exceeds the size limit, this call returns an error
`MAX_NOTEBOOK_SIZE_EXCEEDED.` This API does not support exporting a
library.

At this time we do not support the `direct_download` parameter and
returns a base64 encoded string.

[See More](https://docs.databricks.com/api/workspace/workspace/export).

## See also

Other Workspace API:
[`db_workspace_delete()`](https://databrickslabs.github.io/brickster/reference/db_workspace_delete.md),
[`db_workspace_get_status()`](https://databrickslabs.github.io/brickster/reference/db_workspace_get_status.md),
[`db_workspace_import()`](https://databrickslabs.github.io/brickster/reference/db_workspace_import.md),
[`db_workspace_list()`](https://databrickslabs.github.io/brickster/reference/db_workspace_list.md),
[`db_workspace_mkdirs()`](https://databrickslabs.github.io/brickster/reference/db_workspace_mkdirs.md)
