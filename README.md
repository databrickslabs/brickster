# [brickster](https://databrickslabs.github.io/brickster/) <img src="man/figures/logo.png" align="right" height="139px"/>

<!-- badges: start -->

[![R-CMD-check](https://github.com/databrickslabs/brickster/workflows/R-CMD-check/badge.svg)](https://github.com/databrickslabs/brickster/actions) [![Codecov test coverage](https://codecov.io/gh/databrickslabs/brickster/branch/main/graph/badge.svg)](https://app.codecov.io/gh/databrickslabs/brickster?branch=main)

<!-- badges: end -->

`{brickster}` is the R toolkit for Databricks, it includes:

-   Wrappers for [Databricks API's](https://docs.databricks.com/api/workspace/introduction) (e.g. [`db_cluster_list`](https://databrickslabs.github.io/brickster/reference/db_cluster_list.html), [`db_volume_read`](https://databrickslabs.github.io/brickster/reference/db_volume_read.html))

-   Browser workspace assets via RStudio Connections Pane ([`open_workspace()`](https://databrickslabs.github.io/brickster/reference/open_workspace.html))

-   Interactive Databricks REPL

## Installation

`remotes::install_github("databrickslabs/brickster")`

## Quick Start

``` r
library(brickster)

# only requires `DATABRICKS_HOST` if using OAuth U2M
# first request will open browser window to login
Sys.setenv(DATABRICKS_HOST = "https://<workspace-prefix>.cloud.databricks.com")

# list all SQL warehouses
warehouses <- db_sql_warehouse_list()

# read `data.csv` from a volume
file <- db_volume_read(
  path = "/Volumes/<catalog>/<schema>/<volume>/data.csv",
  tempfile(pattern = ".csv")
)
volume_csv <- readr::read_csv(file)
```

Refer to the ["Connect to a Databricks Workspace"](https://databrickslabs.github.io/brickster/articles/setup-auth.html) article for more details on getting authentication configured.

## `{DBI}` Backend

`{brickster}` provides a complete DBI backend for Databricks SQL warehouses, enabling standard database operations with R:

``` r
library(brickster)
library(DBI)

# Connect to Databricks using DBI (assumes you followed quickstart to authenticate)
con <- dbConnect(
  DatabricksSQL(),
  warehouse_id = "<warehouse-id>"
)

# Standard {DBI} operations
tables <- dbListTables(con)
dbGetQuery(con, "SELECT * FROM samples.nyctaxi.trips LIMIT 5")

# Use with {dbplyr} for {dplyr} syntax
library(dplyr)
library(dbplyr)

nyc_taxi <- tbl(con, I("samples.nyctaxi.trips"))

result <- nyc_taxi |>
  filter(year(tpep_pickup_datetime) == 2016) |>
  group_by(pickup_zip) |>
  summarise(
    trip_count = n(),
    avg_fare = mean(fare_amount, na.rm = TRUE),
    avg_distance = mean(trip_distance, na.rm = TRUE)
  ) |>
  collect()
```

## API Coverage

`{brickster}` is very deliberate with choosing what API's are wrapped. `{brickster}` isn't intended to replace IaC tooling (e.g. [Terraform](#0)) or to be used for account/workspace administration.

| API | Available | Version |
|------------------------------------|-------------------|-------------------|
| [DBFS](https://docs.databricks.com/api/workspace/dbfs) | Yes | 2.0 |
| [Secrets](https://docs.databricks.com/api/workspace/secrets) | Yes | 2.0 |
| [Repos](https://docs.databricks.com/api/workspace/repos) | Yes | 2.0 |
| [mlflow Model Registry](https://docs.databricks.com/api/workspace/modelregistry) | Yes | 2.0 |
| [Clusters](https://docs.databricks.com/api/workspace/clusters) | Yes | 2.0 |
| [Libraries](https://docs.databricks.com/api/workspace/libraries) | Yes | 2.0 |
| [Workspace](https://docs.databricks.com/api/workspace/workspace) | Yes | 2.0 |
| [Endpoints](https://docs.databricks.com/api/workspace/warehouses) | Yes | 2.0 |
| [Query History](https://docs.databricks.com/api/workspace/queryhistory) | Yes | 2.0 |
| [Jobs](https://docs.databricks.com/api/workspace/jobs) | Yes | 2.1 |
| [Volumes (Files)](https://docs.databricks.com/api/workspace/files) | Yes | 2.0 |
| [SQL Statement Execution](https://docs.databricks.com/api/workspace/statementexecution) | Yes | 2.0 |
| [REST 1.2 Commands](https://docs.databricks.com/api/workspace/commandexecution) | Partially | 1.2 |
| [Unity Catalog - Tables](https://docs.databricks.com/api/workspace/tables) | Yes | 2.1 |
| [Unity Catalog - Volumes](https://docs.databricks.com/api/workspace/volumes) | Yes | 2.1 |
| [Unity Catalog](https://docs.databricks.com/api/workspace/catalogs) | Partially | 2.1 |