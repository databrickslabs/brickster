# Create Empty R Vector from Databricks SQL Type

Internal helper that maps Databricks SQL types to appropriate empty R
vectors. Used for creating properly typed empty tibbles from schema
information.

## Usage

``` r
db_sql_type_to_empty_vector(sql_type)
```

## Arguments

- sql_type:

  Character string representing Databricks SQL type

## Value

Empty R vector of appropriate type
