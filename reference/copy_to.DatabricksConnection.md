# Copy data frame to Databricks as table or view

Copy data frame to Databricks as table or view

## Usage

``` r
# S3 method for class 'DatabricksConnection'
copy_to(
  dest,
  df,
  name = deparse(substitute(df)),
  overwrite = FALSE,
  temporary = TRUE,
  ...
)
```

## Arguments

- dest:

  A DatabricksConnection object

- df:

  Data frame to copy

- name:

  Name for the table/view

- overwrite:

  Whether to overwrite existing table/view

- temporary:

  Whether to create as temporary view (default: TRUE, but NOT
  SUPPORTED - will error)

- ...:

  Additional arguments passed to dbWriteTable

## Value

dbplyr table reference

## Details

Note: temporary=TRUE will result in an error as temporary tables are not
supported with the SQL Statement Execution API. Use temporary=FALSE to
create regular tables.
