# Read a Databricks table

Read a Databricks table

## Usage

``` r
# S4 method for class 'DatabricksConnection,character'
dbReadTable(conn, name, ...)
```

## Arguments

- conn:

  A DatabricksConnection object

- name:

  Table name to read

- ...:

  Additional arguments passed to dbGetQuery

## Value

A data.frame with table contents
