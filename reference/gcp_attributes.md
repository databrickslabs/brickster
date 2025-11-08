# GCP Attributes

GCP Attributes

## Usage

``` r
gcp_attributes(use_preemptible_executors = TRUE, google_service_account = NULL)
```

## Arguments

- use_preemptible_executors:

  Boolean (Default: `TRUE`). If `TRUE` Uses preemptible executors

- google_service_account:

  Google service account email address that the cluster uses to
  authenticate with Google Identity. This field is used for
  authentication with the GCS and BigQuery data sources.

## Details

For use with GCS and BigQuery, your Google service account that you use
to access the data source must be in the same project as the SA that you
specified when setting up your Databricks account.

## See also

[`db_cluster_create()`](https://databrickslabs.github.io/brickster/reference/db_cluster_create.md),
[`db_cluster_edit()`](https://databrickslabs.github.io/brickster/reference/db_cluster_edit.md)

Other Cloud Attributes:
[`aws_attributes()`](https://databrickslabs.github.io/brickster/reference/aws_attributes.md),
[`azure_attributes()`](https://databrickslabs.github.io/brickster/reference/azure_attributes.md)
