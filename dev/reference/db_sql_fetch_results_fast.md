# Fetch SQL Query Results (Fast Path)

Fetch SQL Query Results (Fast Path)

## Usage

``` r
db_sql_fetch_results_fast(
  resp,
  statement_id,
  manifest,
  return_arrow = FALSE,
  fetch_timeout = 300,
  row_limit = NULL,
  host = db_host(),
  token = db_token(),
  show_progress = TRUE
)
```
