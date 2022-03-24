# brickster <a href='https://zacdav-db.github.io/brickster/'><img src='man/figures/logo.png' align="right" height="139" /></a>

<!-- badges: start -->
[![R-CMD-check](https://github.com/databricks/brickster/workflows/R-CMD-check/badge.svg)](https://github.com/databricks/brickster/actions)
<!-- badges: end -->

`{brickster}` aims to reduce friction for R users on Databricks by:

-   Providing 1:1 bindings to relevant Databricks API's

-   Mechanism to use Rmarkdown as a Databricks notebook

-   Utility functions to streamline workloads

-   Shiny widgets for RStudio

## Installation

`remotes::install_github("databricks/brickster")`

**NOTE**: Above won't work until repo is public, for now you'll want to clone and install via `remotes::install_local("<path_to_brickster>")`

## Setup Authentication

Please read the vignette, you can open it by running `vignette("setup-auth", package = "brickster")` after installation.

## API Coverage

| API                                                                                                                  | Available | Version |
|----------------------------------------------------------------------------------------------------------------------|-----------|---------|
| [DBFS](https://docs.databricks.com/dev-tools/api/latest/dbfs.html)                                                   | Yes       | 2.0     |
| [Secrets](https://docs.databricks.com/dev-tools/api/latest/secrets.html)                                             | Yes       | 2.0     |
| [Repos](https://docs.databricks.com/dev-tools/api/latest/repos.html)                                                 | Yes       | 2.0     |
| [mlflow Model Registry](https://docs.databricks.com/dev-tools/api/latest/mlflow.html)                                | Yes       | 2.0     |
| [Global Init Scripts](https://docs.databricks.com/dev-tools/api/latest/global-init-scripts.html)                     | Yes       | 2.0     |
| [Clusters](https://docs.databricks.com/dev-tools/api/latest/clusters.html)                                           | Yes       | 2.0     |
| [Libraries](https://docs.databricks.com/dev-tools/api/latest/libraries.html)                                         | Yes       | 2.0     |
| [Workspace](https://docs.databricks.com/dev-tools/api/latest/workspace.html)                                         | Yes       | 2.0     |
| [Endpoints](https://docs.databricks.com/sql/api/sql-endpoints.html)                                                  | Yes       | 2.0     |
| [Query History](https://docs.databricks.com/sql/api/query-history.html)                                              | Yes       | 2.0     |
| [Jobs](https://docs.databricks.com/dev-tools/api/latest/jobs.html)                                                   | Yes       | 2.1     |
| [REST 1.2 Commands](https://docs.databricks.com/dev-tools/api/1.2/index.html)                                        | Partially | 1.2     |
| [Tokens](https://docs.databricks.com/dev-tools/api/latest/tokens.html)                                               | Later     | 2.0     |
| [Delta Live Tables](https://docs.databricks.com/data-engineering/delta-live-tables/delta-live-tables-api-guide.html) | Later     | 2.0     |
| mlflow webhooks (Private Preview)                                                                                    | Later     | 2.0     |
| [Queries & Dashboards](https://docs.databricks.com/sql/api/queries-dashboards.html)                                  | Later     | 2.0     |
| [Instance Pools](https://docs.databricks.com/dev-tools/api/latest/instance-pools.html)                               | Later     | 2.0     |
| mlflow OSS                                                                                                           | Undecided | 2.0     |
| [Cluster Policies](https://docs.databricks.com/dev-tools/api/latest/policies.html)                                   | Never     | 2.0     |
| [Permissions](https://docs.databricks.com/dev-tools/api/latest/permissions.html)                                     | Never     | 2.0     |
| [Token Management](https://docs.databricks.com/dev-tools/api/latest/token-management.html)                           | Never     | 2.0     |
| [Token](https://docs.databricks.com/dev-tools/api/latest/tokens.html)                                                | Never     | 2.0     |
| [SCIM](https://docs.databricks.com/dev-tools/api/latest/scim/index.html)                                             | Never     | 2.0     |
| [Account](https://docs.databricks.com/dev-tools/api/latest/account.html)                                             | Never     | 2.0     |
| [Groups](https://docs.databricks.com/dev-tools/api/latest/groups.html)                                               | Never     | 2.0     |
| [Instance Profiles](https://docs.databricks.com/dev-tools/api/latest/instance-profiles.html)                         | Never     | 2.0     |
| [IP Access List](https://docs.databricks.com/dev-tools/api/latest/ip-access-list.html)                               | Never     | 2.0     |
