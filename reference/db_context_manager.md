# Databricks Execution Context Manager (R6 Class)

Databricks Execution Context Manager (R6 Class)

Databricks Execution Context Manager (R6 Class)

## Details

`db_context_manager()` provides a simple interface to send commands to
Databricks cluster and return the results.

## Methods

### Public methods

- [`db_context_manager$new()`](#method-databricks_context_manager-new)

- [`db_context_manager$close()`](#method-databricks_context_manager-close)

- [`db_context_manager$cmd_run()`](#method-databricks_context_manager-cmd_run)

- [`db_context_manager$clone()`](#method-databricks_context_manager-clone)

------------------------------------------------------------------------

### Method [`new()`](https://rdrr.io/r/methods/new.html)

Create a new context manager object.

#### Usage

    db_context_manager$new(
      cluster_id,
      language = c("r", "py", "scala", "sql", "sh"),
      host = db_host(),
      token = db_token()
    )

#### Arguments

- `cluster_id`:

  The ID of the cluster to execute command on.

- `language`:

  One of `r`, `py`, `scala`, `sql`, or `sh`.

- `host`:

  Databricks workspace URL, defaults to calling
  [`db_host()`](https://databrickslabs.github.io/brickster/reference/db_host.md).

- `token`:

  Databricks workspace token, defaults to calling
  [`db_token()`](https://databrickslabs.github.io/brickster/reference/db_token.md).

#### Returns

A new `databricks_context_manager` object.

------------------------------------------------------------------------

### Method [`close()`](https://rdrr.io/r/base/connections.html)

Destroy the execution context

#### Usage

    db_context_manager$close()

------------------------------------------------------------------------

### Method `cmd_run()`

Execute a command against a Databricks cluster

#### Usage

    db_context_manager$cmd_run(cmd, language = c("r", "py", "scala", "sql", "sh"))

#### Arguments

- `cmd`:

  code to execute against Databricks cluster

- `language`:

  One of `r`, `py`, `scala`, `sql`, or `sh`.

#### Returns

Command results

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    db_context_manager$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
