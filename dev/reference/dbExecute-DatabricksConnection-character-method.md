# Execute statement on Databricks

Execute statement on Databricks

## Usage

``` r
# S4 method for class 'DatabricksConnection,character'
dbExecute(conn, statement, ...)
```

## Arguments

- conn:

  A DatabricksConnection object

- statement:

  SQL statement

- ...:

  Additional arguments (ignored)

## Value

Number of rows in result set (from metadata, without loading data)
