# Write table to Databricks (AsIs name signature)

Write table to Databricks (AsIs name signature)

## Usage

``` r
# S4 method for class 'DatabricksConnection,AsIs,data.frame'
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
  show_progress = conn@show_progress,
  ...
)
```

## Arguments

- conn:

  DatabricksConnection object

- name:

  Table name as AsIs object (from I())

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

- show_progress:

  If `TRUE`, show progress updates while writing. Defaults to the
  connection's `show_progress` setting.

- ...:

  Additional arguments.

## Value

`TRUE` invisibly on success
