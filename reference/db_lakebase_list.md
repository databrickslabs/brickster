# List Database Instances

List Database Instances

## Usage

``` r
db_lakebase_list(
  page_size = 50,
  page_token = NULL,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

- page_size:

  Maximum number of instances to return in a single page.

- page_token:

  Pagination token to retrieve the next page of results.

- host:

  Databricks workspace URL, defaults to calling
  [`db_host()`](https://databrickslabs.github.io/brickster/reference/db_host.md).

- token:

  Databricks workspace token, defaults to calling
  [`db_token()`](https://databrickslabs.github.io/brickster/reference/db_token.md).

- perform_request:

  If `TRUE` (default) the request is performed, if `FALSE` the httr2
  request is returned *without* being performed.

## Value

List

## See also

Other Database API:
[`db_lakebase_creds_generate()`](https://databrickslabs.github.io/brickster/reference/db_lakebase_creds_generate.md),
[`db_lakebase_get()`](https://databrickslabs.github.io/brickster/reference/db_lakebase_get.md),
[`db_lakebase_get_by_uid()`](https://databrickslabs.github.io/brickster/reference/db_lakebase_get_by_uid.md)

## Examples

``` r
if (FALSE) { # \dontrun{
library(brickster)
library(DBI)
library(RPostgres)

# list all lakebase instances
dbs <- db_lakebase_list()

# connect to the first instance available using {RPostgres}
# using identity that brickster is running as generate a token
creds <- db_lakebase_creds_generate(instance_names = dbs[[1]]$name)

con <- dbConnect(
  drv = RPostgres::Postgres(),
  host = dbs[[1]]$read_write_dns,
  user = db_current_user()$userName,
  password = creds$token,
  dbname = "databricks_postgres",
  sslmode = "require"
)

dbListTables(con)
} # }
```
