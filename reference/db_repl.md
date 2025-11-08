# Remote REPL to Databricks Cluster

Remote REPL to Databricks Cluster

## Usage

``` r
db_repl(
  cluster_id,
  language = c("r", "py", "scala", "sql", "sh"),
  host = db_host(),
  token = db_token()
)
```

## Arguments

- cluster_id:

  Cluster Id to create REPL context against.

- language:

  for REPL ('r', 'py', 'scala', 'sql', 'sh') are supported.

- host:

  Databricks workspace URL, defaults to calling
  [`db_host()`](https://databrickslabs.github.io/brickster/reference/db_host.md).

- token:

  Databricks workspace token, defaults to calling
  [`db_token()`](https://databrickslabs.github.io/brickster/reference/db_token.md).

## Details

`db_repl()` will take over the existing console and allow execution of
commands against a Databricks cluster. For RStudio users there are
Addins which can be bound to keyboard shortcuts to improve usability.
