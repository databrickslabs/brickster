# Append rows to an existing Databricks table

Append rows to an existing Databricks table

## Usage

``` r
# S4 method for class 'DatabricksConnection,character,data.frame'
dbAppendTable(conn, name, value, ..., row.names = FALSE)
```

## Arguments

- conn:

  A DatabricksConnection object

- name:

  Table name (character, Id, or SQL)

- value:

  Data frame to append

- ...:

  Additional arguments

- row.names:

  If TRUE, preserve row names as a column

## Value

TRUE invisibly on success
