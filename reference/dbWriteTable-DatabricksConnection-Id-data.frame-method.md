# Write a data frame to Databricks table (Id method)

Write a data frame to Databricks table (Id method)

## Usage

``` r
# S4 method for class 'DatabricksConnection,Id,data.frame'
dbWriteTable(
  conn,
  name,
  value,
  overwrite = FALSE,
  append = FALSE,
  row.names = FALSE,
  temporary = FALSE,
  field.types = NULL,
  staging_volume = NULL,
  progress = TRUE,
  ...
)
```

## Arguments

- conn:

  A DatabricksConnection object

- name:

  Table name as Id object

- value:

  Data frame to write

- overwrite:

  If `TRUE`, overwrite existing table

- append:

  If `TRUE`, append to existing table

- row.names:

  If `TRUE`, preserve row names as a column

- temporary:

  If `TRUE`, create temporary table (NOT SUPPORTED - will error)

- field.types:

  Named character vector of SQL types for columns

- staging_volume:

  Optional volume path for large dataset staging

- progress:

  If `TRUE`, show progress bar for file uploads (default: `TRUE`)

- ...:

  Additional arguments

## Value

`TRUE` invisibly on success
