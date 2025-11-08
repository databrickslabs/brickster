# Reads Environment Variables

Reads Environment Variables

## Usage

``` r
read_env_var(key = c("token", "host", "wsid"), profile = NULL, error = TRUE)
```

## Arguments

- key:

  The value to fetch from profile. One of `token`, `host`, or `wsid`

- profile:

  Character, the name of the profile to retrieve values

- error:

  Boolean, when key isn't found should error be raised

## Value

named list of values associated with profile

## Details

Fetches relevant environment variables based on profile
