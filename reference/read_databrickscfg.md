# Reads Databricks CLI Config

Reads Databricks CLI Config

## Usage

``` r
read_databrickscfg(
  key = c("token", "host", "wsid", "client_id", "client_secret"),
  profile = NULL,
  error = TRUE
)
```

## Arguments

- key:

  The value to fetch from profile. One of `token`, `host`, `wsid`,
  `client_id`, or `client_secret`

- profile:

  Character, the name of the profile to retrieve values

## Value

named list of values associated with profile

## Details

Reads `.databrickscfg` file and retrieves the values associated to a
given profile. Brickster searches for the config file in the user's home
directory by default. To see where this is you can run
Sys.getenv("HOME") on unix-like operating systems, or,
Sys.getenv("USERPROFILE") on windows. An alternate location will be used
if the environment variable `DATABRICKS_CONFIG_FILE` is set.
