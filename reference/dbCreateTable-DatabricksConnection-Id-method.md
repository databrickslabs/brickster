# Create an empty Databricks table (Id method)

Create an empty Databricks table (Id method)

## Usage

``` r
# S4 method for class 'DatabricksConnection,Id'
dbCreateTable(conn, name, fields, ..., row.names = NULL, temporary = FALSE)
```

## Arguments

- conn:

  A DatabricksConnection object

- name:

  Table name as Id object

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
