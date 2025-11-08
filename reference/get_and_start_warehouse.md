# Get and Start Warehouse

Get and Start Warehouse

## Usage

``` r
get_and_start_warehouse(
  id,
  polling_interval = 5,
  host = db_host(),
  token = db_token()
)
```

## Arguments

- id:

  ID of the SQL warehouse.

- polling_interval:

  Number of seconds to wait between status checks

- host:

  Databricks workspace URL, defaults to calling
  [`db_host()`](https://databrickslabs.github.io/brickster/reference/db_host.md).

- token:

  Databricks workspace token, defaults to calling
  [`db_token()`](https://databrickslabs.github.io/brickster/reference/db_token.md).

## Value

[`db_sql_warehouse_get()`](https://databrickslabs.github.io/brickster/reference/db_sql_warehouse_get.md)

## Details

Get information regarding a Databricks cluster. If the cluster is
inactive it will be started and wait until the cluster is active.

## See also

[`db_sql_warehouse_get()`](https://databrickslabs.github.io/brickster/reference/db_sql_warehouse_get.md)
and
[`db_sql_warehouse_start()`](https://databrickslabs.github.io/brickster/reference/db_sql_warehouse_start.md).

Other Warehouse API:
[`db_sql_global_warehouse_get()`](https://databrickslabs.github.io/brickster/reference/db_sql_global_warehouse_get.md),
[`db_sql_warehouse_create()`](https://databrickslabs.github.io/brickster/reference/db_sql_warehouse_create.md),
[`db_sql_warehouse_delete()`](https://databrickslabs.github.io/brickster/reference/db_sql_warehouse_delete.md),
[`db_sql_warehouse_edit()`](https://databrickslabs.github.io/brickster/reference/db_sql_warehouse_edit.md),
[`db_sql_warehouse_get()`](https://databrickslabs.github.io/brickster/reference/db_sql_warehouse_get.md),
[`db_sql_warehouse_list()`](https://databrickslabs.github.io/brickster/reference/db_sql_warehouse_list.md),
[`db_sql_warehouse_start()`](https://databrickslabs.github.io/brickster/reference/db_sql_warehouse_start.md),
[`db_sql_warehouse_stop()`](https://databrickslabs.github.io/brickster/reference/db_sql_warehouse_stop.md)
