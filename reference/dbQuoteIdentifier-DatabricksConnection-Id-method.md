# Quote complex identifiers (schema.table)

Quote complex identifiers (schema.table)

## Usage

``` r
# S4 method for class 'DatabricksConnection,Id'
dbQuoteIdentifier(conn, x, ...)
```

## Arguments

- conn:

  A DatabricksConnection object

- x:

  Id object with catalog/schema/table components

- ...:

  Additional arguments (ignored)

## Value

SQL object with quoted identifier components
