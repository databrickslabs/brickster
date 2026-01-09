# Poll a Query Until Successful

Poll a Query Until Successful

## Usage

``` r
db_sql_exec_poll_for_success(
  statement_id,
  interval = 1,
  show_progress = TRUE,
  host = db_host(),
  token = db_token()
)
```

## Arguments

- statement_id:

  String, query execution `statement_id`

- interval:

  Number of seconds between status checks.

- show_progress:

  If `TRUE`, show progress updates during polling (default: `TRUE`)

- host:

  Databricks workspace URL, defaults to calling
  [`db_host()`](https://databrickslabs.github.io/brickster/reference/db_host.md).

- token:

  Databricks workspace token, defaults to calling
  [`db_token()`](https://databrickslabs.github.io/brickster/reference/db_token.md).
