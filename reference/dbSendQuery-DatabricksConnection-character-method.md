# Send query to Databricks (asynchronous)

Send query to Databricks (asynchronous)

## Usage

``` r
# S4 method for class 'DatabricksConnection,character'
dbSendQuery(conn, statement, disposition = conn@disposition, ...)
```

## Arguments

- conn:

  A DatabricksConnection object

- statement:

  SQL statement to execute

- disposition:

  Query disposition mode. Defaults to the connection's `disposition`
  setting.

- ...:

  Additional arguments (ignored)

## Value

A DatabricksResult object
