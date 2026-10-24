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
  ...,
  query_tags = NULL
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

- query_tags:

  Optional named list of execution-level query tags, for example
  `list(team = "informatics", environment = "dev")`. Supply at most 20
  tags with unique, non-empty names and single string values. Use a
  `NULL` value for a key-only tag. `NULL` or
  [`list()`](https://rdrr.io/r/base/list.html) omits tags from the
  request. Tags are recorded in `system.query.history.query_tags`; they
  are distinct from the saved-query metadata `tags` in
  [`db_query_create()`](https://databrickslabs.github.io/brickster/reference/db_query_create.md).

## Value

A DatabricksConnection object

## Details

Provide either `warehouse_id` or `http_path`. When `http_path` is
supplied, the warehouse ID is extracted from the `/warehouses/<id>`
segment. Connections are stateless: connection-level `query_tags` are
sent with each statement, including connection validation, metadata
queries, and table writes. They do not create a server-side SQL session.

## See also

Other DBI Methods:
[`dbExecute,DatabricksConnection,character-method`](https://databrickslabs.github.io/brickster/reference/dbExecute-DatabricksConnection-character-method.md),
[`dbGetQuery,DatabricksConnection,character-method`](https://databrickslabs.github.io/brickster/reference/dbGetQuery-DatabricksConnection-character-method.md),
[`dbSendQuery,DatabricksConnection,character-method`](https://databrickslabs.github.io/brickster/reference/dbSendQuery-DatabricksConnection-character-method.md),
[`dbSendStatement,DatabricksConnection,character-method`](https://databrickslabs.github.io/brickster/reference/dbSendStatement-DatabricksConnection-character-method.md)
