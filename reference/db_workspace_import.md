# Import Notebook/Directory (Workspaces)

Import a notebook or the contents of an entire directory.

## Usage

``` r
db_workspace_import(
  path,
  file = NULL,
  content = NULL,
  format = c("AUTO", "SOURCE", "HTML", "JUPYTER", "DBC", "R_MARKDOWN"),
  language = NULL,
  overwrite = FALSE,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

- path:

  Absolute path of the notebook or directory.

- file:

  Path of local file to upload. See `formats` parameter.

- content:

  Content to upload, this will be base64-encoded and has a limit of
  10MB.

- format:

  One of `AUTO`, `SOURCE`, `HTML`, `JUPYTER`, `DBC`, `R_MARKDOWN`.
  Default is `SOURCE`.

- language:

  One of `R`, `PYTHON`, `SCALA`, `SQL`. Required when `format` is
  `SOURCE` otherwise ignored.

- overwrite:

  Flag that specifies whether to overwrite existing object. `FALSE` by
  default. For `DBC` overwrite is not supported since it may contain a
  directory.

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

`file` and `content` are mutually exclusive. If both are specified
`content` will be ignored.

If path already exists and `overwrite` is set to `FALSE`, this call
returns an error `RESOURCE_ALREADY_EXISTS.` You can use only `DBC`
format to import a directory.

## See also

Other Workspace API:
[`db_workspace_delete()`](https://databrickslabs.github.io/brickster/reference/db_workspace_delete.md),
[`db_workspace_export()`](https://databrickslabs.github.io/brickster/reference/db_workspace_export.md),
[`db_workspace_get_status()`](https://databrickslabs.github.io/brickster/reference/db_workspace_get_status.md),
[`db_workspace_list()`](https://databrickslabs.github.io/brickster/reference/db_workspace_list.md),
[`db_workspace_mkdirs()`](https://databrickslabs.github.io/brickster/reference/db_workspace_mkdirs.md)
