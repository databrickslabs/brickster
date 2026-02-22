# Connect to a Databricks Workspace

## Defining Credentials

The [brickster](https://github.com/databrickslabs/brickster) package
connects to a Databricks workspace in three ways:

1.  [OAuth user-to-machine (U2M)
    authentication](https://docs.databricks.com/en/dev-tools/auth/oauth-u2m.html#oauth-user-to-machine-u2m-authentication)
2.  [OAuth machine-to-machine (M2M)
    authentication](https://docs.databricks.com/en/dev-tools/auth/oauth-m2m.html)
3.  [Personal Access Tokens
    (PAT)](https://docs.databricks.com/en/dev-tools/auth/pat.html)

It’s recommended to use option (1) when using
[brickster](https://github.com/databrickslabs/brickster) interactively.
If you need to run code via an automated process, use option (2) or (3).

[brickster](https://github.com/databrickslabs/brickster) will
automatically detect when a session has [Posit Workbench managed
Databricks OAuth
credentials](https://docs.posit.co/ide/server-pro/integration/databricks.html)
enabled. For more information about this authentication flow see the
section [Posit Workbench Managed Databricks OAuth
Credentials](#posit-workbench-managed-databricks-oauth-credentials).

Personal Access Tokens can be generated in a few steps, for a
step-by-step breakdown [refer to the
documentation](https://docs.databricks.com/aws/en/dev-tools/auth).

Once you have a token you’ll be able to store it alongside the workspace
URL in an `.Renviron` file. The `.Renviron` is used for storing the
variables, such as those which may be sensitive (e.g. credentials) and
de-couple them from the code [additional
reading](https://CRAN.R-project.org/package=startup/vignettes/startup-intro.html).

To get started add the following to your `.Renviron`:

- `DATABRICKS_HOST`: The workspace URL

- `DATABRICKS_TOKEN`: Personal access token (*not required if using
  OAuth U2M or M2M*)

- `DATABRICKS_CLIENT_ID`: OAuth M2M client id (*only required for OAuth
  M2M*)

- `DATABRICKS_CLIENT_SECRET`: OAuth M2M client secret (*only required
  for OAuth M2M*)

- `ARM_CLIENT_ID`: Azure AD service principal application id (*only
  required for Azure service principal OAuth M2M*)

- `ARM_CLIENT_SECRET`: Azure AD service principal client secret (*only
  required for Azure service principal OAuth M2M*)

- `ARM_TENANT_ID`: Azure AD tenant id (*only required for Azure service
  principal OAuth M2M*)

- `DATABRICKS_AUTH_TYPE`: Optional auth mode override (`oauth-m2m`,
  `azure-client-secret`, `oauth-u2m`)

- `DATABRICKS_WSID`: The workspace ID
  ([docs](https://docs.databricks.com/workspace/workspace-details.html#workspace-instance-names-urls-and-ids))

`DATABRICKS_WSID` is only required for the RStudio IDE integration with
the connection pane.

Example of entries in `.Renviron`:

    DATABRICKS_HOST=xxxxxxx.cloud.databricks.com
    DATABRICKS_TOKEN=dapi123456789012345678a9bc01234defg5
    DATABRICKS_WSID=123123123123123

For OAuth M2M:

    DATABRICKS_HOST=xxxxxxx.cloud.databricks.com
    DATABRICKS_CLIENT_ID=11111111-2222-3333-4444-555555555555
    DATABRICKS_CLIENT_SECRET=abcdefg1234567890
    DATABRICKS_WSID=123123123123123

For Azure service principal OAuth M2M:

    DATABRICKS_HOST=adb-xxxxxx.xx.azuredatabricks.net
    ARM_CLIENT_ID=11111111-2222-3333-4444-555555555555
    ARM_CLIENT_SECRET=abcdefg1234567890
    ARM_TENANT_ID=aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee

With no explicit auth override,
[brickster](https://github.com/databrickslabs/brickster) attempts
Databricks OAuth M2M (`DATABRICKS_CLIENT_*`), then Azure service
principal OAuth M2M (`ARM_*`), then OAuth U2M. Set
`DATABRICKS_AUTH_TYPE=azure-client-secret` to force Azure service
principal authentication.

**Note**: Recommend creating an `.Renviron` for each project. You can
create `.Renviron` within your user home directory if required.

Restarting your R session will allow those variable to be picked up via
the [brickster](https://github.com/databrickslabs/brickster) package.

## Using Credentials with `{brickster}`

Authentication should now be possible without specifying the credentials
in your R code. You can load
[brickster](https://github.com/databrickslabs/brickster) and list the
clusters within the workspace using
[`db_cluster_list()`](https://databrickslabs.github.io/brickster/reference/db_cluster_list.md),
to access the host/token use
[`db_host()`](https://databrickslabs.github.io/brickster/reference/db_host.md)/[`db_token()`](https://databrickslabs.github.io/brickster/reference/db_token.md)
respectively.

``` r
library(brickster)

# using db_host() and db_token() to get credentials
clusters <- db_cluster_list(host = db_host(), token = db_token())
```

All [brickster](https://github.com/databrickslabs/brickster) functions
have their host/token parameters default to calling
[`db_host()`](https://databrickslabs.github.io/brickster/reference/db_host.md)/[`db_token()`](https://databrickslabs.github.io/brickster/reference/db_token.md)
therefore we can omit explicit calls to the functions.

``` r
# all host/token parameters default to db_host()/db_token()
clusters <- db_cluster_list()
```

When using OAuth U2M or OAuth M2M authentication you don’t define a
token in `.Renviron` and therefore
[`db_token()`](https://databrickslabs.github.io/brickster/reference/db_token.md)
will return `NULL`.

## Managing Multiple Credentials

There are two methods that
[brickster](https://github.com/databrickslabs/brickster) supports to
simplify switching of credentials within an R project/session:

1.  Adding multiple credentials to `.Renviron`, each additional set of
    credentials is differentiated via a suffix
    (e.g. `DATABRICKS_TOKEN_DEV`)
2.  Using a `.databrickscfg` file (primary method in [Databricks
    CLI](https://docs.databricks.com/dev-tools/cli/index.html#set-up-authentication))

To differentiate between (1) and (2) the option `use_databrickscfg` is
used, the following example shows how to switch the session to use
`.databrickscfg`.

``` r
# will use the `DEFAULT` profile in `.databrickscfg`
options(use_databrickscfg = TRUE)

# values returned should be those in profile of `.databrickscfg`
db_host()
db_token()
```

The default behaviour is to read credentials from `.Renviron`. If you
wish to change this it’s recommended to set the option within
`.Rprofile` so that it’s set during initialization of the R session.

### Switching Between Credentials

The `db_profile` option controls which profiles credentials are returned
by
[`db_host()`](https://databrickslabs.github.io/brickster/reference/db_host.md)/[`db_token()`](https://databrickslabs.github.io/brickster/reference/db_token.md)/[`db_wsid()`](https://databrickslabs.github.io/brickster/reference/db_wsid.md).

Profiles enable you to switch contexts between:

- Different workspaces (e.g. development or production)

- Different permissions (e.g. admin or restricted user)

This behaviour works when using credentials specified in either
`.Renviron` or `.databrickscfg`:

``` r
# using .Renviron
db_host() # returns `DB_HOST` (.Renviron)

# switch profile to 'prod'
options(db_profile = "prod")
db_host() # returns `DB_HOST_PROD` (.Renviron)

# set back to default (NULL)
options(db_profile = NULL)
# use .databrickcfg
options(use_databrickscfg = TRUE)
db_host() # returns host from `DEFAULT` profile (.databrickscfg)

options(db_profile = "prod")
db_host() # returns host from `prod` profile in (.datarickscfg)
```

It is expected that profiles in `.Renviron` will adhere to the same
naming convention as default but add an additional suffix.

Here is an example of an `.Renviron` file that has three profiles
(default, dev, prod):

    # default
    DATABRICKS_HOST=xxxxxxx.cloud.databricks.com
    DATABRICKS_TOKEN=dapixxxxxxxxxxxxxxxxxxxxxxxxx
    DATABRICKS_WSID=123123123123123
    # dev
    DATABRICKS_HOST_DEV=xxxxxxx-dev.cloud.databricks.com
    DATABRICKS_TOKEN_DEV=dapixxxxxxxxxxxxxxxxxxxxxxxxx
    DATABRICKS_WSID_DEV=123123123123124
    # prod
    DATABRICKS_HOST_PROD=xxxxxxx-prod.cloud.databricks.com
    DATABRICKS_TOKEN_PROD=dapixxxxxxxxxxxxxxxxxxxxxxxxx
    DATABRICKS_WSID_PROD=123123123123125

### Configuring `.databrickscfg`

For details on configuring please refer to [documentation from
Databricks
CLI](https://docs.databricks.com/dev-tools/cli/index.html#connection-profiles).

There is only one
[brickster](https://github.com/databrickslabs/brickster) specific
feature and it is the inclusion of `wsid` alongside `host`/`token`.

When using OAuth M2M with a `.databrickscfg` profile:

- Databricks service principal fields: `client_id`, `client_secret`
- Azure service principal fields: `azure_client_id`,
  `azure_client_secret`, `azure_tenant_id`
- Optional auth mode override: `auth_type` (`oauth-m2m`,
  `azure-client-secret`, `oauth-u2m`)

If both `DATABRICKS_AUTH_TYPE` (environment variable) and `auth_type`
(`.databrickscfg`) are set, `DATABRICKS_AUTH_TYPE` takes precedence.

`wsid` is used by the connections pane integration in RStudio as the
underlying API’s require it.

### Posit Workbench Managed Databricks OAuth Credentials

Posit Workbench has a [managed Databricks OAuth
credentials](https://docs.posit.co/ide/server-pro/integration/databricks.html)
feature, which allows users to sign into a Databricks workspace from the
home page of Workbench when launching a session and then access
Databricks resources as their own identity. When in an RStudio Pro
session running on Posit Workbench with managed Databricks OAuth
credentials selected,
[brickster](https://github.com/databrickslabs/brickster) functions using
[`db_host()`](https://databrickslabs.github.io/brickster/reference/db_host.md)/[`db_token()`](https://databrickslabs.github.io/brickster/reference/db_token.md)
respectively should just work without needing to specify any credentials
in your R code. See the code below as an example.

``` r
library(brickster)
db_cluster_list()
```

[brickster](https://github.com/databrickslabs/brickster) will
automatically detect when a session has Workbench managed OAuth
credentials and then use the `workbench` profile defined in a
`.databrickscfg` file at the `DATABRICKS_CONFIG_FILE` specified
location. Workbench generates this `.databrickscfg` file in a temporary
directory and should not be modified directly.

To use an alternative `.databrickscfg` file, a different `profile`, an
alternative env variable `DATABRICKS_HOST` or set an env variable
`DATABRICKS_TOKEN`, launch an RStudio Pro session without the Databricks
managed credentials box selected.
