# Get Warehouse

Get Warehouse

## Usage

``` r
db_sql_warehouse_get(
  id,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

- id:

  ID of the SQL warehouse.

- host:

  Databricks workspace URL, defaults to calling
  [`db_host()`](https://databrickslabs.github.io/brickster/reference/db_host.md).

- token:

  Databricks workspace token, defaults to calling
  [`db_token()`](https://databrickslabs.github.io/brickster/reference/db_token.md).

- perform_request:

  If `TRUE` (default) the request is performed, if `FALSE` the httr2
  request is returned *without* being performed.

## See also

Other Warehouse API:
[`db_sql_global_warehouse_get()`](https://databrickslabs.github.io/brickster/reference/db_sql_global_warehouse_get.md),
[`db_sql_warehouse_create()`](https://databrickslabs.github.io/brickster/reference/db_sql_warehouse_create.md),
[`db_sql_warehouse_delete()`](https://databrickslabs.github.io/brickster/reference/db_sql_warehouse_delete.md),
[`db_sql_warehouse_edit()`](https://databrickslabs.github.io/brickster/reference/db_sql_warehouse_edit.md),
[`db_sql_warehouse_list()`](https://databrickslabs.github.io/brickster/reference/db_sql_warehouse_list.md),
[`db_sql_warehouse_start()`](https://databrickslabs.github.io/brickster/reference/db_sql_warehouse_start.md),
[`db_sql_warehouse_stop()`](https://databrickslabs.github.io/brickster/reference/db_sql_warehouse_stop.md),
[`get_and_start_warehouse()`](https://databrickslabs.github.io/brickster/reference/get_and_start_warehouse.md)
