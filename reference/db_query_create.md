# Create a SQL Query

Create a SQL Query

## Usage

``` r
db_query_create(
  warehouse_id,
  query_text,
  display_name,
  description = NULL,
  catalog = NULL,
  schema = NULL,
  parent_path = NULL,
  run_as_mode = c("OWNER", "VIEWER"),
  apply_auto_limit = FALSE,
  auto_resolve_display_name = TRUE,
  tags = list(),
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

- warehouse_id:

  description

- query_text:

  Text of the query to be run.

- display_name:

  Display name of the query that appears in list views, widget headings,
  and on the query page.

- description:

  General description that conveys additional information about this
  query such as usage notes.

- catalog:

  Name of the catalog where this query will be executed.

- schema:

  Name of the schema where this query will be executed.

- parent_path:

  Workspace path of the workspace folder containing the object.

- run_as_mode:

  Sets the "Run as" role for the object.

- apply_auto_limit:

  Whether to apply a 1000 row limit to the query result.

- auto_resolve_display_name:

  Automatically resolve query display name conflicts. Otherwise, fail
  the request if the query's display name conflicts with an existing
  query's display name.

- tags:

  Named list that describes the warehouse. Databricks tags all warehouse
  resources with these tags.

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

Other SQL Queries API:
[`db_query_delete()`](https://databrickslabs.github.io/brickster/reference/db_query_delete.md),
[`db_query_get()`](https://databrickslabs.github.io/brickster/reference/db_query_get.md),
[`db_query_list()`](https://databrickslabs.github.io/brickster/reference/db_query_list.md),
[`db_query_update()`](https://databrickslabs.github.io/brickster/reference/db_query_update.md)
