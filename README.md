# brickster <a href='https://zacdav-db.github.io/brickster/'><img src='man/figures/logo.png' align="right" height="139" /></a>

<!-- badges: start -->
[![R-CMD-check](https://github.com/zacdav-db/brickster/workflows/R-CMD-check/badge.svg)](https://github.com/zacdav-db/brickster/actions)
[![Codecov test
coverage](https://codecov.io/gh/zacdav-db/brickster/branch/main/graph/badge.svg)](https://app.codecov.io/gh/zacdav-db/brickster?branch=main)
<!-- badges: end -->

`{brickster}` aims to reduce friction for R users on Databricks by:

-   Providing 1:1 bindings to relevant Databricks API's

-   Use Rmarkdown as a Databricks notebook

-   Integrate with RStudio Connections Pane (`open_workspace()`)

-   Utility functions to streamline workloads

-   Shiny widgets for RStudio

## Installation

`remotes::install_github("zacdav-db/brickster")`

## Setup Authentication

Docs website has [an article](https://zacdav-db.github.io/brickster/articles/setup-auth.html)
that provides details on how to connect to a Databricks workspace.

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
| [Unity Catalog](https://api-docs.databricks.com/rest/latest/unity-catalog-api-specification-2-1.html)                | Partially | 2.1     |
| [Tokens](https://docs.databricks.com/dev-tools/api/latest/tokens.html)                                               | Undecided | 2.0     |
| [Delta Live Tables](https://docs.databricks.com/data-engineering/delta-live-tables/delta-live-tables-api-guide.html) | Undecided | 2.0     |
| mlflow webhooks (Private Preview)                                                                                    | Later     | 2.0     |
| [Queries & Dashboards](https://docs.databricks.com/sql/api/queries-dashboards.html)                                  | Undecided | 2.0     |
| [Instance Pools](https://docs.databricks.com/dev-tools/api/latest/instance-pools.html)                               | Undecided | 2.0     |
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
