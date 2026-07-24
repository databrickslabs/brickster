# Connect to Databricks SQL Warehouse

Connect to Databricks SQL Warehouse

## Usage

``` r
# S4 method for class 'DatabricksDriver'
dbConnect(
  drv,
  warehouse_id = NULL,
  http_path = NULL,
  catalog = NULL,
  schema = NULL,
  staging_volume = NULL,
  disposition = c("EXTERNAL_LINKS", "INLINE"),
  max_active_connections = 30,
  fetch_timeout = 300,
  show_progress = TRUE,
  token = db_token(),
  host = db_host(),
  ...
)
```

## Arguments

- drv:

  A DatabricksDriver object

- warehouse_id:

  Optional ID of the SQL warehouse to connect to

- http_path:

  Optional HTTP path for the SQL warehouse; if provided, the warehouse
  ID is extracted from this path

- catalog:

  Optional catalog name to use as default

- schema:

  Optional schema name to use as default

- staging_volume:

  Optional volume path for large dataset staging

- disposition:

  Query disposition mode to use by default for DBI query results. Use
  `"EXTERNAL_LINKS"` for large results or `"INLINE"` for smaller results
  that must avoid direct cloud-storage result downloads.

- max_active_connections:

  Maximum number of concurrent download connections when fetching query
  results (default: 30)

- fetch_timeout:

  Timeout in seconds for downloading each result chunk (default: 300)

- show_progress:

  If `TRUE`, show progress updates by default for DBI queries, dbplyr
  collection, and table writes (default: `TRUE`)

- token:

  Authentication token (defaults to db_token())

- host:

  Databricks workspace host (defaults to db_host())

- ...:

  Additional arguments (ignored)

## Value

A DatabricksConnection object

## Details

Provide either `warehouse_id` or `http_path`. When `http_path` is
supplied, the warehouse ID is extracted from the `/warehouses/<id>`
segment.
