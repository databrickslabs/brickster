# brickster 0.2.15

-   The workspace Connections pane identifies managed and foreign Iceberg tables as `ICEBERG`, distinguishes Delta tables with Iceberg reads as `DELTA (UniForm: Iceberg)`, and shows Iceberg metadata instead of Delta protocol versions. Tables without a source format, including metric views, no longer fail when opening metadata (#311, @zacdav).
-   The RStudio connection pane now shows the storage location, last commit time, and minimum reader and writer versions of Delta tables (#304, @m-muecke).
-   `db_jobs_repair_run()` now sends `job_parameters` correctly (#307, @m-muecke).
-   `access_control_req_group()` now sends the group as `group_name`, so jobs created with group permissions no longer fail with "Principal name not defined" (#305, @m-muecke).
-   `dbListFields()` no longer returns extra rows for partitioned and clustered tables (#306, @m-muecke).
-   Fixed `db_sql_query()`, `dbGetQuery()`, and `dbFetch()` silently returning only the first chunk of `INLINE` results. Additional chunks are fetched in order up to the requested row limit (#303, @zacdav).
-   `db_list_all_pages()` collects all records from token-paginated listings, omitting pagination metadata automatically. Pass a listing function and its arguments, for example `db_list_all_pages(db_cluster_list, page_size = 100)` (#301, @zacdav-db).
-   Cluster wrappers now use Clusters API 2.1. **Breaking change:** `db_cluster_list()` and `db_cluster_events()` return full single-page responses, preserving pagination tokens; extract `$clusters` or `$events` for records. Both accept `page_size` and `page_token`. The Connections pane follows all cluster pages (#301, @zacdav-db).
-   `db_cluster_events()` deprecates `offset`/`limit` in favor of `page_token`/`page_size` ahead of Databricks' November 30, 2026 migration deadline. Legacy arguments default to `NULL`; explicitly supplied values still work with a warning but cannot be mixed with token pagination. Obtain tokens from preceding responses rather than converting numeric offsets. Millisecond timestamps are now preserved without integer overflow (#301, @zacdav-db).
-   `cumprod()` now uses built-in Databricks SQL functions instead of requiring sparklyr's session-registered aggregate. Cumulative products use a row frame and propagate `NULL` values to subsequent rows in each group (#295, @zacdav-db).
-   **Breaking change:** `db_jobs_list()` and `db_jobs_runs_list()` now return the full single-page API response, including pagination tokens and metadata. Extract `$jobs` or `$runs` to access the records. `offset` now defaults to `NULL` to enable token pagination; explicit numeric offsets are still forwarded. Use `page_token` from the preceding response to fetch another page. Job and run get wrappers also accept `page_token` for additional array elements. Use named arguments with these four wrappers because their argument order has changed (#282, @zacdav).
-   Fixed the workspace connection pane's Catalog availability check so accessible Unity Catalog resources appear (#283, @zacdav).
-   The RStudio connection pane now follows all Unity Catalog listing pages for catalogs, schemas, tables, volumes, models, functions, and model versions, including empty pages with continuation tokens. Volume details are fetched by name so volumes beyond the first listing page can be inspected. `db_uc_volumes_get()` now sends `include_browse` as a query parameter, and the pane handles optional metadata omitted from browse-only responses (#283, @zacdav).
-   Volume-based `dbWriteTable()` now creates the schema requested by `field.types`, including `CHAR`/`VARCHAR` length limits. Volume writes and appends use `INSERT` to convert staged values to the target column types (#287, @zacdav).
-   `db_volume_list()` now accepts `page_size` and `page_token`. Directory downloads and recursive deletion follow every listing page, preventing files beyond the first page from being omitted. Listing failures now stop recursive deletion instead of being treated as empty directories (#281, @zacdav).
-   `db_volume_upload_dir()` now creates each parent directory only once, avoiding repeated API calls for files in the same directory (#269, @zacdav-db).
-   `dbWriteTable()` and `dbAppendTable()` now write POSIXct values as epoch microseconds without shifting their time zone, using the same microsecond conversion as volume-based writes (#298, @m-muecke).
-   Standard-path table writes now detect binary columns once per column, avoiding quadratic serialization time for lists of raw vectors (#268, @zacdav-db).
-   Volume file requests now encode reserved characters and literal percent sequences in paths correctly, preventing `#` and `?` in filenames from changing the request target (#267, @zacdav-db).
-   `db_volume_dir_delete()` now respects `perform_request = FALSE` when `recursive = TRUE`, returning a directory-delete request without listing or deleting contents (#266, @zacdav-db).
-   `db_cluster_create()` and `db_cluster_edit()` no longer ignore `log_conf` (#299, @m-muecke).
-   `db_vs_indexes_upsert_data()` no longer rounds numbers to four decimal places (#308, @m-muecke).
-   Volume-backed `dbWriteTable()` and `dbAppendTable()` avoid an extra staging-directory creation request before uploading files (#309, @m-muecke).
-   Volume-backed `dbWriteTable()` no longer uses the random seed to name staging directories (@m-muecke).
-   Databricks CLI authentication now limits token retrieval to 60 seconds instead of waiting up to 60,000 seconds (#296, @m-muecke).

# brickster 0.2.14

-   Fixed OAuth U2M and M2M authentication across multiple Databricks workspaces in one R session by isolating OAuth clients and cached tokens per workspace (#256, @zacdav-db)
-   OAuth tokens are now refreshed 40 seconds before expiry, avoiding Databricks API rejections during the final 30 seconds of a token's lifetime; this requires `{httr2}` 1.3.0 or later (#258, @zacdav-db)
-   Added `databricks-cli` authentication support for profiles created by `databricks auth login`; `{brickster}` obtains tokens through `databricks auth token`, caches only the short-lived access token in memory, and leaves durable credentials and refresh to the CLI (#258, @zacdav-db)
-   Authentication mode overrides now come from `auth_type` in the selected `.databrickscfg` profile; replace `DATABRICKS_AUTH_TYPE` with the profile field. Environment-only authentication continues to infer the mode from available credentials (#258, @zacdav-db)
-   Fixed `dbWriteTable()` and `dbAppendTable()` standard-path writes for binary columns, which now use Databricks `BINARY` types and `X'...'` literals when no staging volume is configured (#246, @zacdav-db)
-   `dbConnect()` now preserves Databricks API error details when its validation query fails (#247, @zacdav)
-   `db_perform_request()` and `db_perform_response()` now preserve useful error messages when Databricks returns non-JSON error bodies such as empty, plain-text, or HTML responses (#247, @zacdav)
-   Fixed `git_source()` erroring when `type` was left at its default (#225, @m-muecke)
-   Fixed Unity Catalog volume file requests so `db_volume_*` paths containing spaces are encoded correctly (#233, @zacdav-db)
-   `db_cluster_events()` now forwards the `event_types` argument to the API, which was previously ignored (#236, @m-muecke)
-   `db_sql_warehouse_create()` and `db_sql_warehouse_edit()` now forward the `tags` argument to the API, which was previously ignored (#240, @m-muecke)
-   Unity Catalog list helpers now preserve `next_page_token` metadata in list responses for catalogs, schemas, tables, and volumes; their list arguments are sent as documented query parameters (#244, @zacdav-db)
-   `db_uc_volumes_list()` now forwards the `max_results`, `include_browse`, and `page_token` arguments to the API, which were previously ignored (#228, @m-muecke)
-   `db_vs_indexes_query()` now sends the `score_threshold` argument to the API, which was previously ignored (#235, @m-muecke)
-   Added `show_progress` to `dbConnect()` for the DBI backend; `dbGetQuery()`, `dbFetch()`, `dbWriteTable()`, and dbplyr `collect()` now use the connection default while preserving per-call `show_progress` overrides (#223, @zacdav-db)

# brickster 0.2.13

-   Enabled `db_request()` retries for transient low-level HTTP request failures, improving resilience to intermittent curl/HTTP2 framing errors (#215)
-   Added a DBI connection-level `disposition` setting so `dbSendQuery()` and default `dbGetQuery()` calls can use `INLINE` results when direct cloud-storage downloads are blocked (#205)
-   Added Azure AD service principal OAuth M2M support (`ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_TENANT_ID`) with optional `DATABRICKS_AUTH_TYPE` override (`oauth-m2m`, `azure-client-secret`, `oauth-u2m`); default auth resolution now prefers Azure M2M over U2M when ARM credentials are present (#185)
-   Marked DBFS REST wrappers (`db_dbfs_*`) as deprecated and moved them to internal-only, guiding users towards using volumes (`db_volume_*`)
-   Added `db_volume_download_dir()` for parallel directory downloads from Unity Catalog volumes to local directories
-   Renamed `preserve_structure` to `recursive` in `db_volume_upload_dir()` and `db_volume_download_dir()` for consistent directory traversal semantics
-   Added a new vignette for working with volumes
-   Added compact, colorized `{cli}` S3 print methods for `db_cluster_get()`/`db_cluster_list()`, `db_sql_warehouse_get()`/`db_sql_warehouse_list()`, and `db_jobs_get()`/`db_jobs_list()` that preserve nested list structures while improving at-a-glance summaries
-   Standardized DBI write progress argument naming: `dbWriteTable()` and internal `db_write_table_volume()` now use `show_progress` (#201)

# brickster 0.2.12

-   Fixed `dbplyr::compute` interaction for DBI backend (#184)
-   Added OAuth M2M support for workspace-level service principal authentication (#173, #103)
-   DBI connections accept `http_path` as an alternative to `warehouse_id` and extract the warehouse ID from `/sql/1.0/warehouses/<id>`.
-   Added RStudio/Positron Connections Pane support for the DBI backend.
-   Added DBI helpers for `dbCreateTable()`, `dbReadTable()`, and `dbRemoveTable()` with `Id`/`AsIs` support, plus offline tests for DBI table helpers.
-   Optimized SQL result fetching for single-chunk external links by using the inline link from the initial response when available.
-   Increment version of testthat required (\>= 3.3.0)

# brickster 0.2.11

-   Added Lakebase workspace database helpers (`db_lakebase_*`) including credential generation, instance listing, instance lookup by name or UID, and catalog retrieval (#113)
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
