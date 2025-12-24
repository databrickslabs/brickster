# Create an empty Databricks table

Create an empty Databricks table

## Usage

``` r
# S4 method for class 'DatabricksConnection,character'
dbCreateTable(conn, name, fields, ..., row.names = NULL, temporary = FALSE)
```

## Arguments

- conn:

  A DatabricksConnection object

- name:

  Table name to create

- fields:

  Either a named character vector of types or a data frame

- ...:

  Additional arguments (ignored)

- row.names:

  Ignored (included for DBI compatibility)

- temporary:

  If TRUE, create temporary table (NOT SUPPORTED - will error)

## Value

TRUE invisibly on success
