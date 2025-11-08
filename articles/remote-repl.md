# Databricks REPL

## Running Code Remotely

[brickster](https://github.com/databrickslabs/brickster) provides
mechanisms to run code against Databricks, below is an overview of the
available of those in the package:

[TABLE]

Databricks
[REPL](https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop)
([`db_repl()`](https://databrickslabs.github.io/brickster/reference/db_repl.md))
will be the focus of this article.

## What is the Databricks REPL?

The REPL temporarily connects the existing R console to a Databricks
cluster (via [command execution
APIs](https://docs.databricks.com/api/workspace/commandexecution)) and
allows code in all supported languages to be sent interactively - as if
it were running locally.

### Getting Started

Using the REPL is simple, to start just provide `cluster_id`:

``` r
# start REPL
db_repl(cluster_id = "<insert cluster id>")
```

The REPL will check the clusters state and start the cluster if
inactive. The default language is `R`.

After successfully connecting to the cluster you can run commands
against the remote compute from the local session.

### Switching Languages

The REPL has a shortcut you can enter `:<language>` to change the active
language. You can change between the following languages:

| Language | Shortcut |
|----------|----------|
| R        | `:r`     |
| Python   | `:py`    |
| SQL      | `:sql`   |
| Scala    | `:scala` |
| Shell    | `:sh`    |

When you change between languages all variables should persist unless
REPL is exited.

### Limitations

- Development environments (e.g. RStudio, Positron) won’t display
  variables from the remote contexts in the environment pane

- HTML content will only render for Python,
  [htmlwidgets](https://github.com/ramnathv/htmlwidgets) rendering is
  restricted due to [notebook limitations that require a
  workaround](https://docs.databricks.com/en/visualizations/htmlwidgets.html)
  currently

- Not designed to work with interactive serverless compute

- Cannot persist or recover sessions

- Multi-line expressions are only supported for R. Python, Scala, and
  SQL are limited to single line expressions.
