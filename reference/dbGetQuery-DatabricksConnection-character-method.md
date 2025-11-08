# Execute SQL query and return results

Execute SQL query and return results

## Usage

``` r
# S4 method for class 'DatabricksConnection,character'
dbGetQuery(
  conn,
  statement,
  disposition = "EXTERNAL_LINKS",
  show_progress = TRUE,
  ...
)
```

## Arguments

- conn:

  A DatabricksConnection object

- statement:

  SQL statement to execute

- disposition:

  Query disposition mode: "EXTERNAL_LINKS" (default) for large results,
  "INLINE" for small metadata queries (automatically chooses appropriate
  format)

- show_progress:

  If TRUE, show progress updates during query execution (default: TRUE)

- ...:

  Additional arguments passed to underlying query execution

## Value

A data.frame with query results
