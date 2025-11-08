# Azure Attributes

Azure Attributes

## Usage

``` r
azure_attributes(
  first_on_demand = 1,
  availability = c("SPOT_WITH_FALLBACK", "SPOT", "ON_DEMAND"),
  spot_bid_max_price = -1
)
```

## Arguments

- first_on_demand:

  Number of nodes of the cluster that will be placed on on-demand
  instances. If this value is greater than 0, the cluster driver node
  will be placed on an on-demand instance. If this value is greater than
  or equal to the current cluster size, all nodes will be placed on
  on-demand instances. If this value is less than the current cluster
  size, `first_on_demand` nodes will be placed on on-demand instances
  and the remainder will be placed on availability instances. This value
  does not affect cluster size and cannot be mutated over the lifetime
  of a cluster.

- availability:

  One of `SPOT_WITH_FALLBACK`, `SPOT`, `ON_DEMAND.` Type used for all
  subsequent nodes past the `first_on_demand` ones. If `first_on_demand`
  is zero, this availability type will be used for the entire cluster.

- spot_bid_max_price:

  The max bid price used for Azure spot instances. You can set this to
  greater than or equal to the current spot price. You can also set this
  to -1 (the default), which specifies that the instance cannot be
  evicted on the basis of price. The price for the instance will be the
  current price for spot instances or the price for a standard instance.
  You can view historical pricing and eviction rates in the Azure
  portal.

## See also

[`db_cluster_create()`](https://databrickslabs.github.io/brickster/reference/db_cluster_create.md),
[`db_cluster_edit()`](https://databrickslabs.github.io/brickster/reference/db_cluster_edit.md)

Other Cloud Attributes:
[`aws_attributes()`](https://databrickslabs.github.io/brickster/reference/aws_attributes.md),
[`gcp_attributes()`](https://databrickslabs.github.io/brickster/reference/gcp_attributes.md)
