# Connect to Databricks SQL Warehouse

Connect to Databricks SQL Warehouse

## Usage

``` r
# S4 method for class 'DatabricksDriver'
dbConnect(
  drv,
  warehouse_id,
  catalog = NULL,
  schema = NULL,
  staging_volume = NULL,
  max_active_connections = 30,
  fetch_timeout = 300,
  token = db_token(),
  host = db_host(),
  ...
)
```

## Arguments

- drv:

  A DatabricksDriver object

- warehouse_id:

  ID of the SQL warehouse to connect to

- catalog:

  Optional catalog name to use as default

- schema:

  Optional schema name to use as default

- staging_volume:

  Optional volume path for large dataset staging

- max_active_connections:

  Maximum number of concurrent download connections when fetching query
  results (default: 30)

- fetch_timeout:

  Timeout in seconds for downloading each result chunk (default: 300)

- token:

  Authentication token (defaults to db_token())

- host:

  Databricks workspace host (defaults to db_host())

- ...:

  Additional arguments (ignored)

## Value

A DatabricksConnection object
