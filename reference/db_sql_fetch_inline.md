# Fetch Inline SQL Query Results

Reuses the initial chunk and fetches subsequent chunks in order,
stopping once the requested row limit is satisfied. Converts the
combined rows once to preserve consistent column types across chunks.

## Usage

``` r
db_sql_fetch_inline(
  resp,
  row_limit = NULL,
  fetch_timeout = 300,
  host = db_host(),
  token = db_token()
)
```

## Arguments

- resp:

  Query status response from SQL execution

- row_limit:

  Maximum number of rows to return. Fetching stops once enough rows are
  available; any excess rows in the last fetched chunk are discarded.

- fetch_timeout:

  Integer, timeout in seconds for downloading each result chunk

- host:

  Databricks host

- token:

  Databricks token

## Value

A tibble containing all requested INLINE result rows.
