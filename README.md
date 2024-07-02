# [brickster](https://databrickslabs.github.io/brickster/) <a href='https://zacdav-db.github.io/brickster/'><img src="man/figures/logo.png" align="right" height="139"/></a>

<!-- badges: start -->

[![R-CMD-check](https://github.com/zacdav-db/brickster/workflows/R-CMD-check/badge.svg)](https://github.com/zacdav-db/brickster/actions) [![Codecov test coverage](https://codecov.io/gh/zacdav-db/brickster/branch/main/graph/badge.svg)](https://app.codecov.io/gh/zacdav-db/brickster?branch=main)

<!-- badges: end -->

`{brickster}` is the R toolkit for Databricks, it includes:

-   Wrappers for [Databricks API's](https://docs.databricks.com/api/workspace/introduction) (e.g. [`db_cluster_list`](https://databrickslabs.github.io/brickster/reference/db_cluster_list.html), [`db_volume_read`](https://databrickslabs.github.io/brickster/reference/db_volume_read.html))

-   Browser workspace assets via RStudio Connections Pane ([`open_workspace()`](https://databrickslabs.github.io/brickster/reference/open_workspace.html))

-   Exposes the [`databricks-sql-connector`](https://github.com/databricks/databricks-sql-python) via `{reticulate}` ([docs](https://databrickslabs.github.io/brickster/reference/index.html#sql-connector))

-   [Utility functions to streamline workloads in Databricks notebooks](https://databrickslabs.github.io/brickster/reference/index.html#databricks-notebook-helpers)

-   [Use `{rmarkdown}` notebooks as a Databricks notebook](https://databrickslabs.github.io/brickster/articles/rmarkdown-databricks-notebook.html)

## Installation

`remotes::install_github("databrickslabs/brickster")`

## Quick Start

``` r
library(brickster)

# requires `DATABRICKS_HOST` only if using OAuth U2M
# first request will open browser window to login
Sys.setenv(DATABRICKS_HOST = "<workspace-prefix>.cloud.databricks.com")

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

## API Coverage

`{brickster}` is very deliberate with choosing what API's are wrapped. `{brickster}` isn't intended to replace IaC tooling (e.g. [Terraform](#0)) or to be used for account/workspace administration.

| API                                                                                                   | Available | Version |
|------------------------------------|-------------------|-------------------|
| [DBFS](https://docs.databricks.com/dev-tools/api/latest/dbfs.html)                                    | Yes       | 2.0     |
| [Secrets](https://docs.databricks.com/dev-tools/api/latest/secrets.html)                              | Yes       | 2.0     |
| [Repos](https://docs.databricks.com/dev-tools/api/latest/repos.html)                                  | Yes       | 2.0     |
| [mlflow Model Registry](https://docs.databricks.com/dev-tools/api/latest/mlflow.html)                 | Yes       | 2.0     |
| [Clusters](https://docs.databricks.com/dev-tools/api/latest/clusters.html)                            | Yes       | 2.0     |
| [Libraries](https://docs.databricks.com/dev-tools/api/latest/libraries.html)                          | Yes       | 2.0     |
| [Workspace](https://docs.databricks.com/dev-tools/api/latest/workspace.html)                          | Yes       | 2.0     |
| [Endpoints](https://docs.databricks.com/sql/api/sql-endpoints.html)                                   | Yes       | 2.0     |
| [Query History](https://docs.databricks.com/sql/api/query-history.html)                               | Yes       | 2.0     |
| [Jobs](https://docs.databricks.com/dev-tools/api/latest/jobs.html)                                    | Yes       | 2.1     |
| [Volumes (Files)](https://docs.databricks.com/api/workspace/files)                                    | Yes       | 2.0     |
| [SQL Statement Execution](https://docs.databricks.com/api/workspace/statementexecution)               | Yes       | 2.0     |
| [REST 1.2 Commands](https://docs.databricks.com/dev-tools/api/1.2/index.html)                         | Partially | 1.2     |
| [Unity Catalog](https://api-docs.databricks.com/rest/latest/unity-catalog-api-specification-2-1.html) | Partially | 2.1     |
