# AWS Attributes

AWS Attributes

## Usage

``` r
aws_attributes(
  first_on_demand = 1,
  availability = c("SPOT_WITH_FALLBACK", "SPOT", "ON_DEMAND"),
  zone_id = NULL,
  instance_profile_arn = NULL,
  spot_bid_price_percent = 100,
  ebs_volume_type = c("GENERAL_PURPOSE_SSD", "THROUGHPUT_OPTIMIZED_HDD"),
  ebs_volume_count = 1,
  ebs_volume_size = NULL,
  ebs_volume_iops = NULL,
  ebs_volume_throughput = NULL
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

- zone_id:

  Identifier for the availability zone/datacenter in which the cluster
  resides. You have three options: availability zone in same region as
  the Databricks deployment, `auto` which selects based on available
  IPs, `NULL` which will use the default availability zone.

- instance_profile_arn:

  Nodes for this cluster will only be placed on AWS instances with this
  instance profile. If omitted, nodes will be placed on instances
  without an instance profile. The instance profile must have previously
  been added to the Databricks environment by an account administrator.
  This feature may only be available to certain customer plans.

- spot_bid_price_percent:

  The max price for AWS spot instances, as a percentage of the
  corresponding instance type’s on-demand price. For example, if this
  field is set to 50, and the cluster needs a new i3.xlarge spot
  instance, then the max price is half of the price of on-demand
  i3.xlarge instances. Similarly, if this field is set to 200, the max
  price is twice the price of on-demand i3.xlarge instances. If not
  specified, the default value is 100. When spot instances are requested
  for this cluster, only spot instances whose max price percentage
  matches this field will be considered. For safety, we enforce this
  field to be no more than 10000.

- ebs_volume_type:

  Either `GENERAL_PURPOSE_SSD` or `THROUGHPUT_OPTIMIZED_HDD`

- ebs_volume_count:

  The number of volumes launched for each instance. You can choose up to
  10 volumes. This feature is only enabled for supported node types.
  Legacy node types cannot specify custom EBS volumes. For node types
  with no instance store, at least one EBS volume needs to be specified;
  otherwise, cluster creation will fail. These EBS volumes will be
  mounted at `/ebs0`, `/ebs1`, and etc. Instance store volumes will be
  mounted at `/local_disk0`, `/local_disk1`, and etc.

  If EBS volumes are attached, Databricks will configure Spark to use
  only the EBS volumes for scratch storage because heterogeneously sized
  scratch devices can lead to inefficient disk utilization. If no EBS
  volumes are attached, Databricks will configure Spark to use instance
  store volumes.

  If EBS volumes are specified, then the Spark configuration
  `spark.local.dir` will be overridden.

- ebs_volume_size:

  The size of each EBS volume (in `GiB`) launched for each instance. For
  general purpose SSD, this value must be within the range `100 - 4096`.
  For throughput optimized HDD, this value must be within the range
  `500 - 4096`.

  Custom EBS volumes cannot be specified for the legacy node types
  (memory-optimized and compute-optimized).

- ebs_volume_iops:

  The number of IOPS per EBS gp3 volume. This value must be between 3000
  and 16000. The value of IOPS and throughput is calculated based on AWS
  documentation to match the maximum performance of a gp2 volume with
  the same volume size.

- ebs_volume_throughput:

  The throughput per EBS gp3 volume, in `MiB` per second. This value
  must be between 125 and 1000.

## Details

If `ebs_volume_iops`, `ebs_volume_throughput`, or both are not
specified, the values will be inferred from the throughput and IOPS of a
gp2 volume with the same disk size, by using the following calculation:

|                      |                                   |                |
|----------------------|-----------------------------------|----------------|
| **Disk size**        | **IOPS**                          | **Throughput** |
| Greater than 1000    | 3 times the disk size up to 16000 | 250            |
| Between 170 and 1000 | 3000                              | 250            |
| Below 170            | 3000                              | 128            |

## See also

[`db_cluster_create()`](https://databrickslabs.github.io/brickster/reference/db_cluster_create.md),
[`db_cluster_edit()`](https://databrickslabs.github.io/brickster/reference/db_cluster_edit.md)

Other Cloud Attributes:
[`azure_attributes()`](https://databrickslabs.github.io/brickster/reference/azure_attributes.md),
[`gcp_attributes()`](https://databrickslabs.github.io/brickster/reference/gcp_attributes.md)
