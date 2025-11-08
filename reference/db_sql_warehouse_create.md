# Create Warehouse

Create Warehouse

## Usage

``` r
db_sql_warehouse_create(
  name,
  cluster_size,
  min_num_clusters = 1,
  max_num_clusters = 1,
  auto_stop_mins = 30,
  tags = list(),
  spot_instance_policy = c("COST_OPTIMIZED", "RELIABILITY_OPTIMIZED"),
  enable_photon = TRUE,
  warehouse_type = c("CLASSIC", "PRO"),
  enable_serverless_compute = NULL,
  disable_uc = FALSE,
  channel = c("CHANNEL_NAME_CURRENT", "CHANNEL_NAME_PREVIEW"),
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

- name:

  Name of the SQL warehouse. Must be unique.

- cluster_size:

  Size of the clusters allocated to the warehouse. One of `2X-Small`,
  `X-Small`, `Small`, `Medium`, `Large`, `X-Large`, `2X-Large`,
  `3X-Large`, `4X-Large`.

- min_num_clusters:

  Minimum number of clusters available when a SQL warehouse is running.
  The default is 1.

- max_num_clusters:

  Maximum number of clusters available when a SQL warehouse is running.
  If multi-cluster load balancing is not enabled, this is limited to 1.

- auto_stop_mins:

  Time in minutes until an idle SQL warehouse terminates all clusters
  and stops. Defaults to 30. For Serverless SQL warehouses
  (`enable_serverless_compute` = `TRUE`), set this to 10.

- tags:

  Named list that describes the warehouse. Databricks tags all warehouse
  resources with these tags.

- spot_instance_policy:

  The spot policy to use for allocating instances to clusters. This
  field is not used if the SQL warehouse is a Serverless SQL warehouse.

- enable_photon:

  Whether queries are executed on a native vectorized engine that speeds
  up query execution. The default is `TRUE`.

- warehouse_type:

  Either "CLASSIC" (default), or "PRO"

- enable_serverless_compute:

  Whether this SQL warehouse is a Serverless warehouse. To use a
  Serverless SQL warehouse, you must enable Serverless SQL warehouses
  for the workspace. If Serverless SQL warehouses are disabled for the
  workspace, the default is `FALSE` If Serverless SQL warehouses are
  enabled for the workspace, the default is `TRUE`.

- disable_uc:

  If `TRUE` will use Hive Metastore (HMS). If `FALSE` (default), then it
  will be enabled for Unity Catalog (UC).

- channel:

  Whether to use the current SQL warehouse compute version or the
  preview version. Databricks does not recommend using preview versions
  for production workloads. The default is `CHANNEL_NAME_CURRENT.`

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
[`db_sql_warehouse_delete()`](https://databrickslabs.github.io/brickster/reference/db_sql_warehouse_delete.md),
[`db_sql_warehouse_edit()`](https://databrickslabs.github.io/brickster/reference/db_sql_warehouse_edit.md),
[`db_sql_warehouse_get()`](https://databrickslabs.github.io/brickster/reference/db_sql_warehouse_get.md),
[`db_sql_warehouse_list()`](https://databrickslabs.github.io/brickster/reference/db_sql_warehouse_list.md),
[`db_sql_warehouse_start()`](https://databrickslabs.github.io/brickster/reference/db_sql_warehouse_start.md),
[`db_sql_warehouse_stop()`](https://databrickslabs.github.io/brickster/reference/db_sql_warehouse_stop.md),
[`get_and_start_warehouse()`](https://databrickslabs.github.io/brickster/reference/get_and_start_warehouse.md)
