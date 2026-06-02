# Read a Databricks table (Id method)

Read a Databricks table (Id method)

## Usage

``` r
# S4 method for class 'DatabricksConnection,Id'
dbReadTable(conn, name, ...)
```

## Arguments

- conn:

  A DatabricksConnection object

- name:

  Table name as Id object

- ...:

  Additional arguments passed to dbGetQuery

## Value

A data.frame with table contents
