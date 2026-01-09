# Create temporary views and tables in Databricks

Create temporary views and tables in Databricks

## Usage

``` r
# S3 method for class 'DatabricksConnection'
sql_query_save(con, sql, name, temporary = TRUE, ...)
```

## Arguments

- con:

  A DatabricksConnection object

- sql:

  SQL query to save as table/view

- name:

  Name for the temporary view or table

- temporary:

  Whether the object should be temporary (default: `TRUE`)

- ...:

  Additional arguments (ignored)

## Value

The table/view name (invisibly)
