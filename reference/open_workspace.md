# Connect to Databricks Workspace

Connect to Databricks Workspace

## Usage

``` r
open_workspace(host = db_host(), token = db_token(), name = NULL)
```

## Arguments

- host:

  Databricks workspace URL, defaults to calling
  [`db_host()`](https://databrickslabs.github.io/brickster/reference/db_host.md).

- token:

  Databricks workspace token, defaults to calling
  [`db_token()`](https://databrickslabs.github.io/brickster/reference/db_token.md).

- name:

  Desired name to assign the connection

## Examples

``` r
if (FALSE) { # \dontrun{
open_workspace(host = db_host(), token = db_token, name = "MyWorkspace")
} # }
```
