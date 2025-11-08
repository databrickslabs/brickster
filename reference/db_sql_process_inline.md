# Process Inline SQL Query Results

Internal helper that processes inline JSON_ARRAY results from a
completed query. Used for metadata queries and small result sets.

## Usage

``` r
db_sql_process_inline(result_data, manifest, row_limit = NULL)
```

## Arguments

- result_data:

  Result data from inline query response

- manifest:

  Query result manifest containing schema information

- row_limit:

  Integer, limit number of rows returned

## Value

tibble with query results
