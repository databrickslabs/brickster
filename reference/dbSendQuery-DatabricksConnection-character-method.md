# Send query to Databricks (asynchronous)

Send query to Databricks (asynchronous)

## Usage

``` r
# S4 method for class 'DatabricksConnection,character'
dbSendQuery(conn, statement, ...)
```

## Arguments

- conn:

  A DatabricksConnection object

- statement:

  SQL statement to execute

- ...:

  Additional arguments (ignored)

## Value

A DatabricksResult object
