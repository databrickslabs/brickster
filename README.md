# brickster <a href='https://zacdav-db.github.io/brickster/'><img src="man/figures/logo.png" align="right" height="139"/></a>

<!-- badges: start -->

[![R-CMD-check](https://github.com/zacdav-db/brickster/workflows/R-CMD-check/badge.svg)](https://github.com/zacdav-db/brickster/actions) [![Codecov test coverage](https://codecov.io/gh/zacdav-db/brickster/branch/main/graph/badge.svg)](https://app.codecov.io/gh/zacdav-db/brickster?branch=main)

<!-- badges: end -->

`{brickster}` aims to reduce friction for R users on Databricks by:

-   Providing bindings to relevant Databricks API's

-   Use RMarkdown as a Databricks notebook

-   Integrate with RStudio Connections Pane (`open_workspace()`)

-   Exposes the [`databricks-sql-connector`](https://github.com/databricks/databricks-sql-python) via `{reticulate}`

-   Utility functions to streamline workloads

## Installation

`remotes::install_github("zacdav-db/brickster")`

## Setup Authentication

Docs website has [an article](https://zacdav-db.github.io/brickster/articles/setup-auth.html) that provides details on how to connect to a Databricks workspace.

## API Coverage

| API                                                                                                   | Available | Version |
|-------------------------------------------------------------------------------------------------------|-----------|---------|
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
