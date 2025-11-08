# Fetch Databricks Workspace ID

Workspace ID, optionally specified to make connections pane more
powerful. Specified as an environment variable `DATABRICKS_WSID`.
`.databrickscfg` will be searched if `db_profile` and
`use_databrickscfg` are set or if Posit Workbench managed OAuth
credentials are detected.

Refer to [api authentication
docs](https://docs.databricks.com/aws/en/dev-tools/auth)

## Usage

``` r
db_wsid(profile = default_config_profile())
```

## Arguments

- profile:

  Profile to use when fetching from environment variable (e.g.
  `.Renviron`) or `.databricksfg` file

## Value

databricks workspace ID

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
[`db_host()`](https://databrickslabs.github.io/brickster/reference/db_host.md),
[`db_read_netrc()`](https://databrickslabs.github.io/brickster/reference/db_read_netrc.md),
[`db_token()`](https://databrickslabs.github.io/brickster/reference/db_token.md)
