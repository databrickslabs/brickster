# Run a Command

Run a Command

## Usage

``` r
db_context_command_run(
  cluster_id,
  context_id,
  language = c("python", "sql", "scala", "r"),
  command = NULL,
  command_file = NULL,
  options = list(),
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

- language:

  The language for the context. One of `python`, `sql`, `scala`, `r`.

- command:

  The command string to run.

- command_file:

  The path to a file containing the command to run.

- options:

  Named list of values used downstream. For example, a 'displayRowLimit'
  override (used in testing).

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
[`db_context_command_run_and_wait()`](https://databrickslabs.github.io/brickster/reference/db_context_command_run_and_wait.md),
[`db_context_command_status()`](https://databrickslabs.github.io/brickster/reference/db_context_command_status.md),
[`db_context_create()`](https://databrickslabs.github.io/brickster/reference/db_context_create.md),
[`db_context_destroy()`](https://databrickslabs.github.io/brickster/reference/db_context_destroy.md),
[`db_context_status()`](https://databrickslabs.github.io/brickster/reference/db_context_status.md)
