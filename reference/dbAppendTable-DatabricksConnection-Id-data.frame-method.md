# Append rows to an existing Databricks table (Id method)

Append rows to an existing Databricks table (Id method)

## Usage

``` r
# S4 method for class 'DatabricksConnection,Id,data.frame'
dbAppendTable(conn, name, value, ..., row.names = FALSE)
```

## Arguments

- conn:

  A DatabricksConnection object

- name:

  Table name as Id object

- value:

  Data frame to append

- ...:

  Additional arguments

- row.names:

  If TRUE, preserve row names as a column

## Value

TRUE invisibly on success
