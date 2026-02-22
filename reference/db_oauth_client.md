# Create OAuth 2.0 Client

Create OAuth 2.0 Client

## Usage

``` r
db_oauth_client(
  host = db_host(),
  client_id = db_client_id(),
  client_secret = db_client_secret(),
  azure_client_id = db_azure_client_id(),
  azure_client_secret = db_azure_client_secret(),
  azure_tenant_id = db_azure_tenant_id(),
  auth_type = db_auth_type()
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

- azure_client_id:

  Azure AD service principal application id.

- azure_client_secret:

  Azure AD service principal client secret.

- azure_tenant_id:

  Azure AD tenant id.

- auth_type:

  Optional explicit auth mode override from `DATABRICKS_AUTH_TYPE`.

## Value

List containing `client`
([`httr2::oauth_client()`](https://httr2.r-lib.org/reference/oauth_client.html)),
`auth_url`, `auth_mode`, `is_m2m`, `scope`, and `token_params`.

## Details

Creates an OAuth 2.0 Client for U2M or M2M flows.

With no explicit `auth_type`, the default order is Databricks OAuth M2M,
then Azure service principal M2M, then OAuth U2M. Set
`auth_type = "azure-client-secret"` to force Azure service principal
M2M.
