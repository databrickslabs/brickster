# Create OAuth 2.0 Client

Create OAuth 2.0 Client

## Usage

``` r
db_oauth_client(host = db_host())
```

## Arguments

- host:

  Databricks workspace URL, defaults to calling
  [`db_host()`](https://databrickslabs.github.io/brickster/reference/db_host.md).

## Value

List that contains httr2_oauth_client and relevant auth url

## Details

Creates an OAuth 2.0 Client, support for U2M flows only. May later be
extended for account U2M and all M2M flows.
