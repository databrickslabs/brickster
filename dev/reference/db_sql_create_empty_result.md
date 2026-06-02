# Create Empty Data Frame from Query Manifest

Helper function that creates an empty data frame with proper column
types based on the query result manifest schema. Used when query returns
zero rows.

## Usage

``` r
db_sql_create_empty_result(manifest)
```

## Arguments

- manifest:

  Query result manifest containing schema information

## Value

tibble with zero rows but correct column types
