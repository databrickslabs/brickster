# Create table with explicit schema before inserting values

Create table with explicit schema before inserting values

## Usage

``` r
db_create_table_as_select_values(
  conn,
  quoted_name,
  value,
  field.types,
  temporary = FALSE,
  overwrite = FALSE
)
```
