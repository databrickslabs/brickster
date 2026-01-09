# Create an empty Databricks table (AsIs method)

Create an empty Databricks table (AsIs method)

## Usage

``` r
# S4 method for class 'DatabricksConnection,AsIs'
dbCreateTable(conn, name, fields, ..., row.names = NULL, temporary = FALSE)
```

## Arguments

- conn:

  A DatabricksConnection object

- name:

  Table name as AsIs object (from I())

- fields:

  Either a named character vector of types or a data frame

- ...:

  Additional arguments (ignored)

- row.names:

  Ignored (included for DBI compatibility)

- temporary:

  If `TRUE`, create temporary table (NOT SUPPORTED - will error)

## Value

`TRUE` invisibly on success
