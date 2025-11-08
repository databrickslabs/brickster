# Get Information About an Execution Context

Get Information About an Execution Context

## Usage

``` r
db_context_status(
  cluster_id,
  context_id,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

- cluster_id:

  The ID of the cluster to create the context for.

- context_id:

  The ID of the execution context.

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

Other Execution Context API:
[`db_context_command_cancel()`](https://databrickslabs.github.io/brickster/reference/db_context_command_cancel.md),
[`db_context_command_parse()`](https://databrickslabs.github.io/brickster/reference/db_context_command_parse.md),
[`db_context_command_run()`](https://databrickslabs.github.io/brickster/reference/db_context_command_run.md),
[`db_context_command_run_and_wait()`](https://databrickslabs.github.io/brickster/reference/db_context_command_run_and_wait.md),
[`db_context_command_status()`](https://databrickslabs.github.io/brickster/reference/db_context_command_status.md),
[`db_context_create()`](https://databrickslabs.github.io/brickster/reference/db_context_create.md),
[`db_context_destroy()`](https://databrickslabs.github.io/brickster/reference/db_context_destroy.md)
