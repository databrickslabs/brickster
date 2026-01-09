# brickster 0.2.12
-   Added OAuth M2M support for workspace-level service principal authentication.
-   Added DBI helpers for `dbCreateTable()`, `dbReadTable()`, and `dbRemoveTable()` with `Id`/`AsIs` support, plus offline tests for DBI table helpers.
-   Optimized SQL result fetching for single-chunk external links by using the inline link from the initial response when available.
-   Increment version of testthat required (\>= 3.3.0)

# brickster 0.2.11
-   Added Lakebase workspace database helpers (`db_lakebase_*`) including
    credential generation, instance listing, instance lookup by name or UID,
    and catalog retrieval (#113)
-   Moving all filesystem related calls to {fs} (#140)
-   The DBI backend now always respects a staging volume when specified, even for small data (#143)
-   `schemaEvolutionMode` is now always `none` when writing to tables with DBI backend and staging volumes (#147)

# brickster 0.2.10
-   Increment version of httr2 required (\>= 1.1.1)
-   DBI connections expose `max_active_connections` and `fetch_timeout` to control result download concurrency and timeouts
-   DBI/dbplyr write table methods now make two transactions (create empty table --\> insert into) to ensure type correctness
-   Allow optional schedules in `db_jobs_reset()` and propagate parameters in reset/update requests.
-   DBI/dbplyr inline writes now preserve single quotes in character columns via explicit escaping (#130)

# brickster 0.2.9

-   Added DBI + dbplyr backend support: `DatabricksSQL()` driver for standard DBI operations
-   Increase support for job level parameters
-   Added `db_jobs_repair_run`

# brickster 0.2.8

-   Added SQL Queries API coverage
-   Updated Jobs to 2.2
-   Added additional tasks for jobs: `for_each_task`, `condition_task`, `sql_query_task`, `sql_file_task`, `run_job_task`
-   Removing the Python SQL connector as `db_sql_query` supersedes it.
-   Added `db_sql_query` to simplify execution of SQL
-   Adjusted `db_repl` to handle mulit-line expressions (R only)
-   Removed RStudio Addins to send lines/selection/files to console
-   Moved arrow to Suggests

# brickster 0.2.7

-   Exporting UC table functions (`db_uc_table*`) (#72)
-   Adding support for `direct_download` option in `db_workspace_export()`
-   Exporting UC Catalog/Schema get/list functions (#72)
-   Adding support for UC Volume management (#72)
-   Fixing command execution context cancel (#86, #87)
-   Adding stricter version requirements for {httr2} (#81, #63)

# brickster 0.2.6

-   Fixing `db_volume_delete()` function (#73, @vladimirobucina)
-   Adjustments to ensure {httr2} changes don't break things (#75, @hadley)

# brickster 0.2.5

-   Adding `db_repl()` a remote REPL to a Databricks cluster (#53)
-   Removing defunct RStudio add-in for browsing Databricks compute
-   Changes to DESCRIPTION file in preperation for CRAN (#64)
-   Removal of `notebook_use_posit_repo()` and `notebook_enable_htmlwidgets()` as they are incompatible with CRAN (#64)
-   Removing kntir engine due to many render edge cases not being solvable
-   Adding shortcuts for REPL under addins
-   Added `db_context_command_run_and_wait`
-   Adjusted tests to use `withr` (#68)

# brickster 0.2.4

-   `open_workspace()` and the rstudio connection pane have been heavily revised to enhance browsing unity catalog and also remove DBFS and WSFS browsing (#52)

# brickster 0.2.3

-   Adding NEWS.md
-   Renamed `set_lib_path` to `add_lib_path` and added the `after` parameter
-   Adding OAuth U2M support (workspace level), considered the default when `DATABRICKS_TOKEN` isn't specified (e.g `db_token()` returns `NULL`)
-   Updating authentication vignette to include information on OAuth
-   Updating README.md to include quick start and clearer information
-   Adding vector search index functions
