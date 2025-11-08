# Fetch SQL Query Results from Completed Query

Internal helper that fetches and processes results from a completed
query. Handles Arrow stream processing and data conversion.

## Usage

``` r
db_sql_fetch_results(
  statement_id,
  manifest,
  return_arrow = FALSE,
  max_active_connections = 30,
  fetch_timeout = 300,
  row_limit = NULL,
  host = db_host(),
  token = db_token(),
  show_progress = TRUE
)
```

## Arguments

- statement_id:

  Query statement ID

- manifest:

  Query result manifest from status response

- return_arrow:

  Boolean, return arrow Table instead of tibble

- max_active_connections:

  Integer for concurrent downloads

- fetch_timeout:

  Integer, timeout in seconds for downloading each result chunk

- row_limit:

  Integer, limit number of rows returned (applied after fetch)

- host:

  Databricks host

- token:

  Databricks token

- show_progress:

  If TRUE, show progress updates during result fetching (default: TRUE)

## Value

tibble or arrow Table with query results
