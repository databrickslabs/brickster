# Returns the default config profile

Returns the default config profile

## Usage

``` r
default_config_profile()
```

## Value

profile name

## Details

Returns the config profile first looking at `DATABRICKS_CONFIG_PROFILE`,
then the `db_profile` option, and then the CLI-selected default profile.
