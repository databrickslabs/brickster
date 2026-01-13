# Create OAuth 2.0 Client

Create OAuth 2.0 Client

## Usage

``` r
db_oauth_client(
  host = db_host(),
  client_id = db_client_id(),
  client_secret = db_client_secret()
)
```

## Arguments

- host:

  Databricks workspace URL, defaults to calling
  [`db_host()`](https://databrickslabs.github.io/brickster/reference/db_host.md).

- client_id:

  OAuth M2M client id.

- client_secret:

  OAuth M2M client secret.

## Value

List that contains
[`httr2::oauth_client()`](https://httr2.r-lib.org/reference/oauth_client.html),
relevant `auth_url`, and `is_m2m`

## Details

Creates an OAuth 2.0 Client for U2M or M2M flows.

If `client_id` and `client_secret` are detected then an M2M auth flow
will occur. Otherwise it falls back to U2M.
