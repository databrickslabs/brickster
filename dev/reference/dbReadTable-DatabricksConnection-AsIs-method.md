# Read a Databricks table (AsIs method)

Read a Databricks table (AsIs method)

## Usage

``` r
# S4 method for class 'DatabricksConnection,AsIs'
dbReadTable(conn, name, ...)
```

## Arguments

- conn:

  A DatabricksConnection object

- name:

  Table name as AsIs object (from I())

- ...:

  Additional arguments passed to dbGetQuery

## Value

A data.frame with table contents
