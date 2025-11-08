# Generate/Fetch Databricks Host

If both `id` and `prefix` are `NULL` then the function will check for
the `DATABRICKS_HOST` environment variable. `.databrickscfg` will be
searched if `db_profile` and `use_databrickscfg` are set or if Posit
Workbench managed OAuth credentials are detected.

When defining `id` and `prefix` you do not need to specify the whole
URL. E.g. `https://<prefix>.<id>.cloud.databricks.com/` is the form to
follow.

## Usage

``` r
db_host(id = NULL, prefix = NULL, profile = default_config_profile())
```

## Arguments

- id:

  The workspace string

- prefix:

  Workspace prefix

- profile:

  Profile to use when fetching from environment variable (e.g.
  `.Renviron`) or `.databricksfg` file

## Value

workspace URL

## Details

The behaviour is subject to change depending if `db_profile` and
`use_databrickscfg` options are set.

- `use_databrickscfg`: Boolean (default: `FALSE`), determines if
  credentials are fetched from profile of `.databrickscfg` or
  `.Renviron`

- `db_profile`: String (default: `NULL`), determines profile used.
  `.databrickscfg` will automatically be used when Posit Workbench
  managed OAuth credentials are detected.

See vignette on authentication for more details.

## See also

Other Databricks Authentication Helpers:
[`db_read_netrc()`](https://databrickslabs.github.io/brickster/reference/db_read_netrc.md),
[`db_token()`](https://databrickslabs.github.io/brickster/reference/db_token.md),
[`db_wsid()`](https://databrickslabs.github.io/brickster/reference/db_wsid.md)
