# Fetch SQL Query Results (Parallel Path)

Fetch SQL Query Results (Parallel Path)

## Usage

``` r
db_sql_fetch_results_parallel(
  statement_id,
  manifest,
  last_chunk_index,
  return_arrow = FALSE,
  max_active_connections = 30,
  fetch_timeout = 300,
  row_limit = NULL,
  host = db_host(),
  token = db_token(),
  show_progress = TRUE
)
```
