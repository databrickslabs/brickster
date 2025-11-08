# \`{DBI}\`/\`{dbplyr}\` backend

## Motivation

Connecting to Databricks SQL Warehouses *typically* involves using one
of the methods below:

[TABLE]

That leaves a void for something that is:

- Native to R

- Easy to install

- Acceptable performance (or better)

- Handles bulk uploads efficiently

- Supports OAuth U2M (no tokens!)

[brickster](https://github.com/databrickslabs/brickster) now provides
both [DBI](https://dbi.r-dbi.org) and
[dbplyr](https://dbplyr.tidyverse.org/) backends for working with
Databricks SQL warehouses.

It uses the [Statement Execution
API](https://docs.databricks.com/api/workspace/statementexecution) in
combination with the [Files
API](https://docs.databricks.com/api/workspace/files) (the latter
specifically for large data uploads).

## Connecting to a Warehouse

Connecting to a Databricks SQL warehouse requires creating a
[DBI](https://dbi.r-dbi.org) connection:

``` r
library(brickster)
library(DBI)
library(dplyr)
library(dbplyr)

# Create connection to SQL warehouse
con <- dbConnect(
  drv = DatabricksSQL(),
  warehouse_id = "<your_warehouse_id>",
  catalog = "samples"
)
```

## `{DBI}` Backend

### Reading Data

Execute SQL directly and return results as data frames:

``` r
trips <- dbGetQuery(con, "SELECT * FROM samples.nyctaxi.trips LIMIT 10")
```

Tables can be references either via
[`Id()`](https://dbi.r-dbi.org/reference/Id.html),
[`I()`](https://rdrr.io/r/base/AsIs.html), or using the name as-is:

``` r
# List available tables
tables <- dbListTables(con)

# Check if specific table exists
dbExistsTable(con, "samples.nyctaxi.trips")
dbExistsTable(con, I("samples.nyctaxi.trips"))
dbExistsTable(con, Id("samples", "nyctaxi", "trips"))

# Get column information
dbListFields(con, "samples.nyctaxi.trips")
dbListFields(con, I("samples.nyctaxi.trips"))
dbListFields(con, Id("samples", "nyctaxi", "trips"))
```

### Writing Data

When writing data (append, overwrite, etc) there are two possible
behaviours:

1.  In-line SQL statement write
2.  Stage `.parquet` files to a Volume directory and `COPY INTO` or
    `CTAS`

For data larger than 50k rows
[brickster](https://github.com/databrickslabs/brickster) will only
permit the use of method (2), which requires `staging_volume` to be
specified when establishing the connection, or directly to
`dbWriteQuery`.

Ensure that `staging_volume` is a valid Volume path and you have
permission to write files.

``` r
# small data (150 rows)
# creates the table schema explicitly then inserts rows inline
dbWriteTable(
  conn = con,
  name = Id(catalog = "<catalog>", schema = "<schema>", table = "<table>"),
  value = iris,
  overwrite = TRUE
)

# bigger data (4 million rows)
# writes parquet files to volume then CTAS
iris_big <- sample_n(iris, replace = TRUE, size = 4000000)

dbWriteTable(
  conn = con,
  name = Id(catalog = "<catalog>", schema = "<schema>", table = "<table>"),
  value = iris_big,
  overwrite = TRUE,
  staging_volume = "/Volumes/<catalog>/<schema>/<volume>/...", # or inherited from connection
  progress = TRUE
)
```

## `{dbplyr}` Backend

### Reading Data

As in the [DBI](https://dbi.r-dbi.org) backend tables can be referenced
either via [`Id()`](https://dbi.r-dbi.org/reference/Id.html),
[`I()`](https://rdrr.io/r/base/AsIs.html), or using the name as-is in
[`tbl()`](https://dplyr.tidyverse.org/reference/tbl.html):

``` r
# Connect to existing tables
tbl(con, "samples.nyctaxi.trips")
tbl(con, I("samples.nyctaxi.trips"))
tbl(con, Id("samples", "nyctaxi", "trips"))
tbl(con, in_catalog("samples", "nyctaxi", "trips"))
```

Chain dplyr operations - they execute remotely on Databricks:

``` r
# Filter and select (translated to SQL)
long_trips <- tbl(con, "samples.nyctaxi.trips") |>
  filter(trip_distance > 10) |>
  select(
    tpep_pickup_datetime,
    tpep_dropoff_datetime,
    trip_distance,
    fare_amount
  )

# View the generated SQL (without executing)
show_query(long_trips)

# Execute and collect results
long_trips |> collect()
```

As a general reminder, call
[`collect()`](https://dplyr.tidyverse.org/reference/compute.html) at the
latest point possible in your analysis to take reduce the required
computation locally.

``` r
# Customer summary statistics
trips_summary <- tbl(con, "samples.nyctaxi.trips") |>
  group_by(pickup_zip) %>%
  summarise(
    trip_count = n(),
    total_fare_amount = sum(fare_amount, na.rm = TRUE),
    total_trip_distance = sum(trip_distance, na.rm = TRUE),
    avg_fare_amount = mean(fare_amount, na.rm = TRUE)
  ) |>
  arrange(desc(avg_fare_amount))

# Execute to get the 20 most expensive pickip zip codes with more than 30 trips
top_zipz <- trips_summary |>
  filter(trip_count > 20) |>
  head(20) |>
  collect()
```

## Writing Data

A key difference is that temporary tables are not supported - this makes
functions like `copy_to` only usable when specifying `temporary` as
`FALSE` which will use `dbWriteTable` to create a table.

``` r
iris_remote <- copy_to(
  con,
  iris,
  "iris_table",
  temporary = FALSE,
  overwrite = TRUE
)
```

## Connection Management

The connection for the `DatabricksSQL` driver is different to other
[DBI](https://dbi.r-dbi.org) backends as it doesn’t have a persistent
session (it’s all just API calls). This means calling `dbDisconnect`
serves no purpose when it comes to freeing resources on the SQL
warehouse.

## `{WebR}` Support

`{bricksters}` core dependencies are all
[`{WebR}`](https://docs.r-wasm.org/webr/latest/) compatible. The backend
uses [nanoarrow](https://arrow.apache.org/nanoarrow/latest/r/) as a
fallback when [arrow](https://github.com/apache/arrow/) is unavailable
(currently [arrow](https://github.com/apache/arrow/) is a `Suggests`).

It’s recommended to always have
[arrow](https://github.com/apache/arrow/) installed to improve the
performance of data loading.
