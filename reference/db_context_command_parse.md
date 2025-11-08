# Parse Command Results

Parse Command Results

## Usage

``` r
db_context_command_parse(x, language = c("r", "py", "scala", "sql"))
```

## Arguments

- x:

  command output from `db_context_command_status` or
  `db_context_manager`'s `cmd_run`

- language:

## Value

command results

## See also

Other Execution Context API:
[`db_context_command_cancel()`](https://databrickslabs.github.io/brickster/reference/db_context_command_cancel.md),
[`db_context_command_run()`](https://databrickslabs.github.io/brickster/reference/db_context_command_run.md),
[`db_context_command_run_and_wait()`](https://databrickslabs.github.io/brickster/reference/db_context_command_run_and_wait.md),
[`db_context_command_status()`](https://databrickslabs.github.io/brickster/reference/db_context_command_status.md),
[`db_context_create()`](https://databrickslabs.github.io/brickster/reference/db_context_create.md),
[`db_context_destroy()`](https://databrickslabs.github.io/brickster/reference/db_context_destroy.md),
[`db_context_status()`](https://databrickslabs.github.io/brickster/reference/db_context_status.md)
