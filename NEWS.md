# brickster 0.2.7

* Exporting UC table functions (`db_uc_table*`) (#72)
* Adding support for `direct_download` option in `db_workspace_export()`
* Exporting UC Catalog/Schema get/list functions (#72)
* Adding support for UC Volume management (#72)

# brickster 0.2.6

* Fixing `db_volume_delete()` function (#73, @vladimirobucina)
* Adjustments to ensure {httr2} changes don't break things (#75, @hadley)

# brickster 0.2.5

* Adding `db_repl()` a remote REPL to a Databricks cluster (#53)
* Removing defunct RStudio add-in for browsing Databricks compute
* Changes to DESCRIPTION file in preperation for CRAN (#64)
* Removal of `notebook_use_posit_repo()` and `notebook_enable_htmlwidgets()`
as they are incompatible with CRAN (#64)
* Removing kntir engine due to many render edge cases not being solvable
* Adding shortcuts for REPL under addins
* Added `db_context_command_run_and_wait`
* Adjusted tests to use `withr` (#68)

# brickster 0.2.4

* `open_workspace()` and the rstudio connection pane have been heavily revised
  to enhance browsing unity catalog and also remove DBFS and WSFS browsing (#52)

# brickster 0.2.3

* Adding NEWS.md
* Renamed `set_lib_path` to `add_lib_path` and added the `after` parameter
* Adding OAuth U2M support (workspace level), considered the default when
  `DATABRICKS_TOKEN` isn't specified (e.g `db_token()` returns `NULL`)
* Updating authentication vignette to include information on OAuth
* Updating README.md to include quick start and clearer information
* Adding vector search index functions
