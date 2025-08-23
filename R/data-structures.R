#' AWS Attributes
#'
#' @param first_on_demand Number of nodes of the cluster that will be placed on
#' on-demand instances. If this value is greater than 0, the cluster driver node
#' will be placed on an on-demand instance. If this value is greater than or
#' equal to the current cluster size, all nodes will be placed on on-demand
#' instances. If this value is less than the current cluster size,
#' `first_on_demand` nodes will be placed on on-demand instances and the
#' remainder will be placed on availability instances. This value does not
#' affect cluster size and cannot be mutated over the lifetime of a cluster.
#' @param availability One of `SPOT_WITH_FALLBACK`, `SPOT`, `ON_DEMAND.` Type
#' used for all subsequent nodes past the `first_on_demand` ones. If
#' `first_on_demand` is zero, this availability type will be used for the entire
#' cluster.
#' @param zone_id Identifier for the availability zone/datacenter in which the
#' cluster resides. You have three options: availability zone in same region as
#' the Databricks deployment, `auto` which selects based on available IPs,
#' `NULL` which will use the default availability zone.
#' @param instance_profile_arn Nodes for this cluster will only be placed on AWS
#' instances with this instance profile. If omitted, nodes will be placed on
#' instances without an instance profile. The instance profile must have
#' previously been added to the Databricks environment by an account
#' administrator. This feature may only be available to certain customer plans.
#' @param spot_bid_price_percent The max price for AWS spot instances, as a
#' percentage of the corresponding instance type’s on-demand price. For example,
#' if this field is set to 50, and the cluster needs a new i3.xlarge spot
#' instance, then the max price is half of the price of on-demand i3.xlarge
#' instances. Similarly, if this field is set to 200, the max price is twice the
#' price of on-demand i3.xlarge instances. If not specified, the default value
#' is 100. When spot instances are requested for this cluster, only spot
#' instances whose max price percentage matches this field will be considered.
#' For safety, we enforce this field to be no more than 10000.
#' @param ebs_volume_type Either `GENERAL_PURPOSE_SSD` or
#' `THROUGHPUT_OPTIMIZED_HDD`
#' @param ebs_volume_count The number of volumes launched for each instance. You
#' can choose up to 10 volumes. This feature is only enabled for supported node
#' types. Legacy node types cannot specify custom EBS volumes. For node types
#' with no instance store, at least one EBS volume needs to be specified;
#' otherwise, cluster creation will fail. These EBS volumes will be mounted at
#' `/ebs0`, `/ebs1`, and etc. Instance store volumes will be mounted at
#' `/local_disk0`, `/local_disk1`, and etc.
#'
#' If EBS volumes are attached, Databricks will configure Spark to use only the
#' EBS volumes for scratch storage because heterogeneously sized scratch devices
#' can lead to inefficient disk utilization. If no EBS volumes are attached,
#' Databricks will configure Spark to use instance store volumes.
#'
#' If EBS volumes are specified, then the Spark configuration `spark.local.dir`
#' will be overridden.
#' @param ebs_volume_size The size of each EBS volume (in `GiB`) launched for
#' each instance. For general purpose SSD, this value must be within the
#' range `100 - 4096`. For throughput optimized HDD, this value must be
#' within the range `500 - 4096`.
#'
#' Custom EBS volumes cannot be specified for the legacy node types
#' (memory-optimized and compute-optimized).
#' @param ebs_volume_iops The number of IOPS per EBS gp3 volume. This value must
#' be between 3000 and 16000. The value of IOPS and throughput is calculated
#' based on AWS documentation to match the maximum performance of a gp2 volume
#' with the same volume size.
#' @param ebs_volume_throughput The throughput per EBS gp3 volume, in `MiB` per
#' second. This value must be between 125 and 1000.
#'
#' @details
#' If `ebs_volume_iops`, `ebs_volume_throughput`, or both are not specified, the
#' values will be inferred from the throughput and IOPS of a gp2 volume with the
#' same disk size, by using the following calculation:
#' \tabular{lcc}{
#'   \strong{Disk size} \tab \strong{IOPS} \tab \strong{Throughput} \cr
#'   Greater than 1000    \tab 3 times the disk size up to 16000 \tab 250\cr
#'   Between 170 and 1000 \tab 3000                              \tab 250\cr
#'   Below 170            \tab 3000                              \tab 128
#' }
#'
#' @seealso [db_cluster_create()], [db_cluster_edit()]
#' @family Cloud Attributes
#'
#' @export
aws_attributes <- function(
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
) {
  # TODO: check inputs
  availability <- match.arg(availability, several.ok = FALSE)
  ebs_volume_type <- match.arg(ebs_volume_type, several.ok = FALSE)

  obj <- list(
    first_on_demand = first_on_demand,
    availability = availability,
    zone_id = zone_id,
    instance_profile_arn = instance_profile_arn,
    spot_bid_price_percent = spot_bid_price_percent,
    ebs_volume_type = ebs_volume_type,
    ebs_volume_count = ebs_volume_count,
    ebs_volume_size = ebs_volume_size,
    ebs_volume_iops = ebs_volume_iops,
    ebs_volume_throughput = ebs_volume_throughput
  )

  obj <- purrr::discard(obj, is.null)
  class(obj) <- c("AwsAttributes", "list")
  obj
}

#' Test if object is of class AwsAttributes
#'
#' @param x An object
#' @return `TRUE` if the object inherits from the `AwsAttributes` class.
#' @export
is.aws_attributes <- function(x) {
  inherits(x, "AwsAttributes")
}

#' GCP Attributes
#'
#' @param use_preemptible_executors Boolean (Default: `TRUE`). If `TRUE` Uses
#' preemptible executors
#' @param google_service_account Google service account email address that the
#' cluster uses to authenticate with Google Identity. This field is used for
#' authentication with the GCS and BigQuery data sources.
#'
#' @details
#' For use with GCS and BigQuery, your Google service account that you use to
#' access the data source must be in the same project as the SA that you
#' specified when setting up your Databricks account.
#'
#' @seealso [db_cluster_create()], [db_cluster_edit()]
#' @family Cloud Attributes
#'
#' @export
gcp_attributes <- function(
  use_preemptible_executors = TRUE,
  google_service_account = NULL
) {
  obj <- list(
    use_preemptible_executors = use_preemptible_executors,
    google_service_account = google_service_account
  )

  obj <- purrr::discard(obj, is.null)
  class(obj) <- c("GcpAttributes", "list")
  obj
}

#' Test if object is of class GcpAttributes
#'
#' @param x An object
#' @return `TRUE` if the object inherits from the `GcpAttributes` class.
#' @export
is.gcp_attributes <- function(x) {
  inherits(x, "GcpAttributes")
}


#' Azure Attributes
#'
#' @param spot_bid_max_price The max bid price used for Azure spot instances.
#' You can set this to greater than or equal to the current spot price. You can
#' also set this to -1 (the default), which specifies that the instance cannot
#' be evicted on the basis of price. The price for the instance will be the
#' current price for spot instances or the price for a standard instance. You
#' can view historical pricing and eviction rates in the Azure portal.
#' @inheritParams aws_attributes
#'
#' @seealso [db_cluster_create()], [db_cluster_edit()]
#' @family Cloud Attributes
#'
#' @export
azure_attributes <- function(
  first_on_demand = 1,
  availability = c("SPOT_WITH_FALLBACK", "SPOT", "ON_DEMAND"),
  spot_bid_max_price = -1
) {
  # TODO: check inputs
  stopifnot(first_on_demand > 0)
  availability <- paste0(match.arg(availability, several.ok = FALSE), "_AZURE")

  obj <- list(
    first_on_demand = first_on_demand,
    availability = availability,
    spot_bid_max_price = spot_bid_max_price
  )

  class(obj) <- c("AzureAttributes", "list")
  obj
}

#' Test if object is of class AzureAttributes
#'
#' @param x An object
#' @return `TRUE` if the object inherits from the `AzureAttributes` class.
#' @export
is.azure_attributes <- function(x) {
  inherits(x, "AzureAttributes")
}


#' Cluster Autoscale
#'
#' Range defining the min and max number of cluster workers.
#'
#' @param min_workers The minimum number of workers to which the cluster can
#' scale down when underutilized. It is also the initial number of workers the
#' cluster will have after creation.
#' @param max_workers The maximum number of workers to which the cluster can
#' scale up when overloaded. `max_workers` must be strictly greater than
#' `min_workers`.
#'
#' @seealso [db_cluster_create()], [db_cluster_edit()]
#' @family Cluster Objects
#'
#' @export
cluster_autoscale <- function(min_workers, max_workers) {
  stopifnot(min_workers > 0)
  stopifnot(min_workers < max_workers)

  obj <- list(
    min_workers = min_workers,
    max_workers = max_workers
  )

  class(obj) <- c("AutoScale", "list")
  obj
}

#' Test if object is of class AutoScale
#'
#' @param x An object
#' @return `TRUE` if the object inherits from the `AutoScale` class.
#' @export
is.cluster_autoscale <- function(x) {
  inherits(x, "AutoScale")
}

#' DBFS Storage Information
#'
#' @param destination DBFS destination. Example: `dbfs:/my/path`.
#'
#' @seealso [cluster_log_conf()], [init_script_info()]
#' @family Cluster Log Configuration Objects
#' @family Init Script Info Objects
#'
#' @export
dbfs_storage_info <- function(destination) {
  obj <- list(
    destination = destination
  )
  class(obj) <- c("DbfsStorageInfo", "list")
  obj
}

#' Test if object is of class DbfsStorageInfo
#'
#' @param x An object
#' @return `TRUE` if the object inherits from the `DbfsStorageInfo` class.
#' @export
is.dbfs_storage_info <- function(x) {
  inherits(x, "DbfsStorageInfo")
}

#' File Storage Information
#'
#' @param destination File destination. Example: `file:/my/file.sh`.
#'
#' @details
#' The file storage type is only available for clusters set up using Databricks
#' Container Services.
#'
#' @seealso [init_script_info()]
#' @family Init Script Info Objects
#'
#' @export
file_storage_info <- function(destination) {
  obj <- list(
    destination = destination
  )
  class(obj) <- c("FileStorageInfo", "list")
  obj
}

#' Test if object is of class FileStorageInfo
#'
#' @param x An object
#' @return `TRUE` if the object inherits from the `FileStorageInfo` class.
#' @export
is.file_storage_info <- function(x) {
  inherits(x, "FileStorageInfo")
}


#' S3 Storage Info
#'
#' @param destination S3 destination. For example: `s3://my-bucket/some-prefix`.
#' You must configure the cluster with an instance profile and the instance
#' profile must have write access to the destination. **You cannot use AWS
#' keys**.
#' @param region S3 region. For example: `us-west-2`. Either region or endpoint
#' must be set. If both are set, endpoint is used.
#' @param endpoint S3 endpoint. For example:
#' `https://s3-us-west-2.amazonaws.com`. Either region or endpoint must be set.
#' If both are set, endpoint is used.
#' @param enable_encryption Boolean (Default: `FALSE`). If `TRUE` Enable server
#' side encryption.
#' @param encryption_type Encryption type, it could be `sse-s3` or `sse-kms`. It
#' is used only when encryption is enabled and the default type is `sse-s3`.
#' @param kms_key KMS key used if encryption is enabled and encryption type is
#' set to `sse-kms`.
#' @param canned_acl Set canned access control list. For example:
#' `bucket-owner-full-control`. If `canned_acl` is set, the cluster instance
#' profile must have `s3:PutObjectAcl` permission on the destination bucket and
#' prefix. The full list of possible canned ACLs can be found in
#' [docs](https://docs.aws.amazon.com/AmazonS3/latest/userguide/acl-overview.html#canned-acl).
#' By default only the object owner gets full control. If you are using cross
#' account role for writing data, you may want to set
#' `bucket-owner-full-control` to make bucket owner able to read the logs.
#'
#' @seealso [cluster_log_conf()], [init_script_info()]
#' @family Cluster Log Configuration Objects
#' @family Init Script Info Objects
#'
#' @export
s3_storage_info <- function(
  destination,
  region = NULL,
  endpoint = NULL,
  enable_encryption = FALSE,
  encryption_type = c("sse-s3", "sse-kms"),
  kms_key = NULL,
  canned_acl = NULL
) {
  encryption_type <- match.arg(encryption_type, several.ok = FALSE)

  obj <- list(
    destination = destination,
    region = region,
    endpoint = endpoint,
    enable_encryption = enable_encryption,
    encryption_type = encryption_type,
    kms_key = kms_key,
    canned_acl = canned_acl
  )

  class(obj) <- c("S3StorageInfo", "list")
  obj
}

#' Test if object is of class S3StorageInfo
#'
#' @param x An object
#' @return `TRUE` if the object inherits from the `S3StorageInfo` class.
#' @export
is.s3_storage_info <- function(x) {
  inherits(x, "S3StorageInfo")
}


#' Cluster Log Configuration
#'
#' Path to cluster log.
#'
#' @param dbfs Instance of [dbfs_storage_info()].
#' @param s3 Instance of [s3_storage_info()].
#'
#' @details `dbfs` and `s3` are mutually exclusive, logs can only be sent to
#' one destination.
#'
#' @family Cluster Log Configuration Objects
#'
#' @export
cluster_log_conf <- function(dbfs = NULL, s3 = NULL) {
  # dbfs or s3 must be specified - but not both
  stopifnot(xor(is.null(dbfs), is.null(s3)))

  if (!is.null(dbfs)) {
    stopifnot(is.dbfs_storage_info(dbfs))
  }

  if (!is.null(s3)) {
    stopifnot(is.s3_storage_info(s3))
  }

  obj <- list(
    dbfs = dbfs,
    s3 = s3
  )

  class(obj) <- c("ClusterLogConf", "list")
  obj
}

#' Test if object is of class ClusterLogConf
#'
#' @param x An object
#' @return `TRUE` if the object inherits from the `ClusterLogConf` class.
#' @export
is.cluster_log_conf <- function(x) {
  inherits(x, "ClusterLogConf")
}


#' Docker Image
#'
#' Docker image connection information.
#'
#' @param url URL for the Docker image.
#' @param username User name for the Docker repository.
#' @param password Password for the Docker repository.
#'
#' @details
#' Uses basic authentication, **strongly** recommended that credentials are not
#' stored in any scripts and environment variables should be used.
#'
#' @seealso [db_cluster_create()], [db_cluster_edit()]
#'
#' @export
docker_image <- function(url, username, password) {
  obj <- list(
    url = url,
    basic_auth = list(
      username = username,
      password = password
    )
  )

  class(obj) <- c("DockerImage", "list")
  obj
}

#' Test if object is of class DockerImage
#'
#' @param x An object
#' @return `TRUE` if the object inherits from the `DockerImage` class.
#' @export
is.docker_image <- function(x) {
  inherits(x, "DockerImage")
}


#' Init Script Info
#'
#' @param ... Accepts multiple instances [s3_storage_info()],
#' [file_storage_info()], or [dbfs_storage_info()].
#'
#' @details
#' [file_storage_info()] is only available for clusters set up using Databricks
#' Container Services.
#'
#' For instructions on using init scripts with Databricks Container Services,
#' see [Use an init script](https://docs.databricks.com/clusters/custom-containers.html#containers-init-script).
#'
#' @seealso [db_cluster_create()], [db_cluster_edit()]
#'
#' @export
init_script_info <- function(...) {
  obj <- list(...)

  # all must be one of `s3_storage_info`, `file_storage_info`, `dbfs_storage_info`
  valid_storage <- vapply(
    obj,
    function(x) {
      is.s3_storage_info(x) | is.file_storage_info(x) | is.dbfs_storage_info(x)
    },
    logical(1)
  )

  stopifnot(all(valid_storage))

  class(obj) <- c("InitScriptInfo", "list")
  obj
}

#' Test if object is of class InitScriptInfo
#'
#' @param x An object
#' @return `TRUE` if the object inherits from the `InitScriptInfo` class.
#' @export
is.init_script_info <- function(x) {
  inherits(x, "InitScriptInfo")
}

#' New Cluster
#'
#' @inheritParams db_cluster_create
#'
#' @seealso [job_task()]
#' @family Task Objects
#'
#' @export
new_cluster <- function(
  num_workers,
  spark_version,
  node_type_id,
  driver_node_type_id = NULL,
  autoscale = NULL,
  cloud_attrs = NULL,
  spark_conf = NULL,
  spark_env_vars = NULL,
  custom_tags = NULL,
  ssh_public_keys = NULL,
  log_conf = NULL,
  init_scripts = NULL,
  enable_elastic_disk = TRUE,
  driver_instance_pool_id = NULL,
  instance_pool_id = NULL,
  kind = c("CLASSIC_PREVIEW"),
  data_security_mode = c(
    "NONE",
    "SINGLE_USER",
    "USER_ISOLATION",
    "LEGACY_TABLE_ACL",
    "LEGACY_PASSTHROUGH",
    "LEGACY_SINGLE_USER",
    "LEGACY_SINGLE_USER_STANDARD",
    "DATA_SECURITY_MODE_STANDARD",
    "DATA_SECURITY_MODE_DEDICATED",
    "DATA_SECURITY_MODE_AUTO"
  )
) {
  # job_cluster_key is reserved for future use
  # TODO: detect if aws/azure/gcp by node_type_ids and see if there is a mismatch

  kind <- match.arg(kind)
  data_security_mode <- match.arg(data_security_mode)

  obj <- list(
    num_workers = num_workers,
    autoscale = autoscale,
    spark_version = spark_version,
    spark_conf = spark_conf,
    node_type_id = node_type_id,
    driver_node_type_id = driver_node_type_id,
    ssh_public_keys = ssh_public_keys,
    custom_tags = custom_tags,
    cluster_log_conf = log_conf,
    init_script_info = init_scripts,
    spark_env_vars = spark_env_vars,
    enable_elastic_disk = enable_elastic_disk,
    driver_instance_pool_id = driver_instance_pool_id,
    instance_pool_id = instance_pool_id
  )

  if (is.aws_attributes(cloud_attrs)) {
    obj[["aws_attributes"]] <- unclass(cloud_attrs)
  } else if (is.azure_attributes(cloud_attrs)) {
    obj[["azure_attributes"]] <- unclass(cloud_attrs)
  } else if (is.gcp_attributes(cloud_attrs)) {
    obj[["gcp_attributes"]] <- unclass(cloud_attrs)
  } else {
    stop(
      "Please use `aws_attributes()`, `azure_attributes()`, or `gcp_attributes()` to specify `cloud_attr`"
    )
  }

  obj <- purrr::discard(obj, is.null)
  class(obj) <- c("NewCluster", "list")
  obj
}

#' Test if object is of class NewCluster
#'
#' @param x An object
#' @return `TRUE` if the object inherits from the `NewCluster` class.
#' @export
is.new_cluster <- function(x) {
  inherits(x, "NewCluster")
}

#' Libraries
#'
#' @param ... Accepts multiple instances of [lib_jar()], [lib_cran()],
#' [lib_maven()], [lib_pypi()], [lib_whl()], [lib_egg()].
#'
#' @details
#' Optional list of libraries to be installed on the cluster that executes the
#' task.
#'
#' @seealso [job_task()], [lib_jar()], [lib_cran()], [lib_maven()],
#' [lib_pypi()], [lib_whl()], [lib_egg()]
#' @family Task Objects
#' @family Library Objects
#'
#' @export
libraries <- function(...) {
  obj <- list(...)

  # all must be one of:
  # `lib_jar`, `lib_cran`, `lib_maven`, `lib_pypi`, `lib_whl`, `lib_egg`
  valid_lib_type <- vapply(obj, is.library, logical(1))
  stopifnot(all(valid_lib_type))

  lib_type <- vapply(
    obj,
    function(x) {
      switch(
        class(x)[1],
        "JarLibrary" = "jar",
        "EggLibrary" = "egg",
        "WhlLibrary" = "whl",
        "PyPiLibrary" = "pypi",
        "MavenLibrary" = "maven",
        "CranLibrary" = "cran"
      )
    },
    character(1)
  )

  lib_objs <- list()
  for (i in seq_along(obj)) {
    lib_objs[[i]] <- setNames(list(obj[[i]]), lib_type[[i]])
  }

  class(lib_objs) <- c("Libraries", "list")
  lib_objs
}

#' Test if object is of class Libraries
#'
#' @param x An object
#' @return `TRUE` if the object inherits from the `Libraries` class.
#' @export
is.libraries <- function(x) {
  inherits(x, "Libraries")
}


#' Jar Library (Scala)
#'
#' @param jar URI of the JAR to be installed. DBFS and S3 URIs are supported.
#' For example: `dbfs:/mnt/databricks/library.jar` or
#' `s3://my-bucket/library.jar`. If S3 is used, make sure the cluster has read
#' access on the library. You may need to launch the cluster with an instance
#' profile to access the S3 URI.
#'
#' @seealso [libraries()]
#' @family Library Objects
#'
#' @export
lib_jar <- function(jar) {
  obj <- list(jar = jar)
  class(obj) <- c("JarLibrary", "Library", "list")
  obj
}

#' Test if object is of class JarLibrary
#'
#' @param x An object
#' @return `TRUE` if the object inherits from the `JarLibrary` class.
#' @export
is.lib_jar <- function(x) {
  inherits(x, "JarLibrary")
}

#' Egg Library (Python)
#'
#' @param egg URI of the egg to be installed. DBFS and S3 URIs are supported.
#' For example: `dbfs:/my/egg` or `s3://my-bucket/egg`. If S3 is used, make sure
#' the cluster has read access on the library. You may need to launch the
#' cluster with an instance profile to access the S3 URI.
#'
#' @seealso [libraries()]
#' @family Library Objects
#'
#' @export
lib_egg <- function(egg) {
  obj <- list(egg = egg)
  class(obj) <- c("EggLibrary", "Library", "list")
  obj
}

#' Test if object is of class EggLibrary
#'
#' @param x An object
#' @return `TRUE` if the object inherits from the `EggLibrary` class.
#' @export
is.lib_egg <- function(x) {
  inherits(x, "EggLibrary")
}

#' Wheel Library (Python)
#'
#' @param whl URI of the wheel or zipped wheels to be installed.
#' DBFS and S3 URIs are supported. For example: `dbfs:/my/whl` or
#' `s3://my-bucket/whl`. If S3 is used, make sure the cluster has read access on
#' the library. You may need to launch the cluster with an instance profile to
#' access the S3 URI. Also the wheel file name needs to use the correct
#' convention. If zipped wheels are to be installed, the file name suffix should
#' be `.wheelhouse.zip`.
#'
#' @seealso [libraries()]
#' @family Library Objects
#'
#' @export
lib_whl <- function(whl) {
  obj <- list(whl = whl)
  class(obj) <- c("WhlLibrary", "Library", "list")
  obj
}

#' Test if object is of class WhlLibrary
#'
#' @param x An object
#' @return `TRUE` if the object inherits from the `WhlLibrary` class.
#' @export
is.lib_whl <- function(x) {
  inherits(x, "WhlLibrary")
}

#' PyPi Library (Python)
#'
#' @param package The name of the PyPI package to install. An optional exact
#' version specification is also supported. Examples: `simplejson` and
#' `simplejson==3.8.0`.
#' @param repo The repository where the package can be found. If not specified,
#' the default pip index is used.
#'
#' @seealso [libraries()]
#' @family Library Objects
#'
#' @export
lib_pypi <- function(package, repo = NULL) {
  obj <- list(
    package = package,
    repo = repo
  )
  class(obj) <- c("PyPiLibrary", "Library", "list")
  obj
}

#' Test if object is of class PyPiLibrary
#'
#' @param x An object
#' @return `TRUE` if the object inherits from the `PyPiLibrary` class.
#' @export
is.lib_pypi <- function(x) {
  inherits(x, "PyPiLibrary")
}

#' Maven Library (Scala)
#'
#' @param coordinates Gradle-style Maven coordinates. For example:
#' `org.jsoup:jsoup:1.7.2`.
#' @param repo Maven repo to install the Maven package from. If omitted, both
#' Maven Central Repository and Spark Packages are searched.
#' @param exclusions List of dependencies to exclude. For example:
#' `list("slf4j:slf4j", "*:hadoop-client")`.
#' [Maven dependency exclusions](https://maven.apache.org/guides/introduction/introduction-to-optional-and-excludes-dependencies.html).
#'
#' @seealso [libraries()]
#' @family Library Objects
#'
#' @export
lib_maven <- function(coordinates, repo = NULL, exclusions = NULL) {
  obj <- list(
    coordinates = coordinates,
    repo = repo,
    exclusions = exclusions
  )
  class(obj) <- c("MavenLibrary", "Library", "list")
  obj
}

#' Test if object is of class MavenLibrary
#'
#' @param x An object
#' @return `TRUE` if the object inherits from the `MavenLibrary` class.
#' @export
is.lib_maven <- function(x) {
  inherits(x, "MavenLibrary")
}

#' Cran Library (R)
#'
#' @param package The name of the CRAN package to install.
#' @param repo The repository where the package can be found. If not specified,
#' the default CRAN repo is used.
#'
#' @seealso [libraries()]
#' @family Library Objects
#'
#' @export
lib_cran <- function(package, repo = NULL) {
  obj <- list(
    package = package,
    repo = repo
  )
  class(obj) <- c("CranLibrary", "Library", "list")
  obj
}

#' Test if object is of class CranLibrary
#'
#' @param x An object
#' @return `TRUE` if the object inherits from the `CranLibrary` class.
#' @export
is.lib_cran <- function(x) {
  inherits(x, "CranLibrary")
}

#' Test if object is of class Library
#'
#' @param x An object
#' @return `TRUE` if the object inherits from the `Library` class.
#' @export
is.library <- function(x) {
  inherits(x, "Library")
}

#' Email Notifications
#'
#' @param on_start List of email addresses to be notified when a run begins.
#' If not specified on job creation, reset, or update, the list is empty, and
#' notifications are not sent.
#' @param on_success List of email addresses to be notified when a run
#' successfully completes. A run is considered to have completed successfully if
#' it ends with a `TERMINATED` `life_cycle_state` and a `SUCCESSFUL`
#' `result_state.` If not specified on job creation, reset, or update, the list
#' is empty, and notifications are not sent.
#' @param on_failure List of email addresses to be notified when a run
#' unsuccessfully completes. A run is considered to have completed
#' unsuccessfully if it ends with an `INTERNAL_ERROR` `life_cycle_state` or a
#' `SKIPPED`, `FAILED`, or `TIMED_OUT` `result_state.` If this is not specified
#' on job creation, reset, or update the list is empty, and notifications are
#' not sent.
#' @param no_alert_for_skipped_runs If `TRUE` (default), do not send email to
#' recipients specified in `on_failure` if the run is skipped.
#'
#' @seealso [job_task()]
#' @family Task Objects
#'
#' @export
email_notifications <- function(
  on_start = NULL,
  on_success = NULL,
  on_failure = NULL,
  no_alert_for_skipped_runs = TRUE
) {
  stopifnot(is.character(on_start))
  stopifnot(is.character(on_success))
  stopifnot(is.character(on_failure))
  stopifnot(is.logical(no_alert_for_skipped_runs))

  obj <- list(
    on_start = on_start,
    on_success = on_success,
    on_failure = on_failure,
    no_alert_for_skipped_runs = no_alert_for_skipped_runs
  )

  class(obj) <- c("JobEmailNotifications", "list")
  obj
}

#' Test if object is of class JobEmailNotifications
#'
#' @param x An object
#' @return `TRUE` if the object inherits from the `JobEmailNotifications` class.
#' @export
is.email_notifications <- function(x) {
  inherits(x, "JobEmailNotifications")
}


#' Cron Schedule
#'
#' @param quartz_cron_expression Cron expression using Quartz syntax that
#' describes the schedule for a job.
#' See [Cron Trigger](https://www.quartz-scheduler.org/documentation/quartz-2.3.0/tutorials/crontrigger.html)
#' for details.
#' @param timezone_id Java timezone ID. The schedule for a job is resolved with
#' respect to this timezone.
#' See [Java TimeZone](https://docs.oracle.com/javase/7/docs/api/java/util/TimeZone.html)
#' for details.
#' @param pause_status Indicate whether this schedule is paused or not. Either
#' `UNPAUSED` (default) or `PAUSED`.
#'
#' @seealso [db_jobs_create()], [db_jobs_reset()], [db_jobs_update()]
#'
#' @export
cron_schedule <- function(
  quartz_cron_expression,
  timezone_id = "Etc/UTC",
  pause_status = c("UNPAUSED", "PAUSED")
) {
  pause_status <- match.arg(pause_status, several.ok = FALSE)

  obj <- list(
    quartz_cron_expression = quartz_cron_expression,
    timezone_id = timezone_id,
    pause_status = pause_status
  )

  class(obj) <- c("CronSchedule", "list")
  obj
}

#' Test if object is of class CronSchedule
#'
#' @param x An object
#' @return `TRUE` if the object inherits from the `CronSchedule` class.
#' @export
is.cron_schedule <- function(x) {
  inherits(x, "CronSchedule")
}


#' Access Control Request
#'
#' @param ... Instances of [access_control_req_user()] or
#' [access_control_req_group()].
#'
#' @seealso [db_jobs_create()], [db_jobs_reset()], [db_jobs_update()]
#'
#' @export
access_control_request <- function(...) {
  obj <- list(...)

  # all must be `access_control_req_user` or `access_control_req_group`
  valid_control <- vapply(
    obj,
    function(x) {
      is.access_control_req_user(x) | is.access_control_req_group(x)
    },
    logical(1)
  )

  stopifnot(all(valid_control))

  class(obj) <- c("AccessControlRequest", "list")
  obj
}

#' Test if object is of class AccessControlRequest
#'
#' @param x An object
#' @return `TRUE` if the object inherits from the `AccessControlRequest` class.
#' @export
is.access_control_request <- function(x) {
  inherits(x, "AccessControlRequest")
}


#' Access Control Request For User
#'
#' @param user_name Email address for the user.
#' @param permission_level Permission level to grant. One of `CAN_MANAGE`,
#' `CAN_MANAGE_RUN`, `CAN_VIEW`, `IS_OWNER`.
#'
#' @seealso [access_control_request()]
#' @family Access Control Request Objects
#'
#' @export
access_control_req_user <- function(
  user_name,
  permission_level = c("CAN_MANAGE", "CAN_MANAGE_RUN", "CAN_VIEW", "IS_OWNER")
) {
  permission_level <- match.arg(permission_level, several.ok = FALSE)

  obj <- list(
    user_name = user_name,
    permission_level = permission_level
  )

  class(obj) <- c("AccessControlRequestForUser", "list")
  obj
}

#' Test if object is of class AccessControlRequestForUser
#'
#' @param x An object
#' @return `TRUE` if the object inherits from the `AccessControlRequestForUser`
#' class.
#' @export
is.access_control_req_user <- function(x) {
  inherits(x, "AccessControlRequestForUser")
}


#' Access Control Request for Group
#'
#' @param group Group name. There are two built-in groups: `users` for all users,
#' and `admins` for administrators.
#' @param permission_level Permission level to grant. One of `CAN_MANAGE`,
#' `CAN_MANAGE_RUN`, `CAN_VIEW`.
#'
#' @seealso [access_control_request()]
#' @family Access Control Request Objects
#'
#' @export
access_control_req_group <- function(
  group,
  permission_level = c("CAN_MANAGE", "CAN_MANAGE_RUN", "CAN_VIEW")
) {
  permission_level <- match.arg(permission_level, several.ok = FALSE)

  obj <- list(
    group = group,
    permission_level = permission_level
  )

  class(obj) <- c("AccessControlRequestForGroup", "list")
  obj
}

#' Test if object is of class AccessControlRequestForGroup
#'
#' @param x An object
#' @return `TRUE` if the object inherits from the `AccessControlRequestForGroup`
#' class.
#' @export
is.access_control_req_group <- function(x) {
  inherits(x, "AccessControlRequestForGroup")
}

#' Git Source for Job Notebook Tasks
#'
#' @param git_url URL of the repository to be cloned by this job. The maximum
#' length is 300 characters.
#' @param git_provider Unique identifier of the service used to host the Git
#' repository. Must be one of: `github`, `bitbucketcloud`, `azuredevopsservices`,
#' `githubenterprise`, `bitbucketserver`, `gitlab`, `gitlabenterpriseedition`,
#' `awscodecommit`.
#' @param reference Branch, tag, or commit to be checked out and used by this job.
#' @param type Type of reference being used, one of: `branch`, `tag`, `commit`.
#'
#' @export
git_source <- function(
  git_url,
  git_provider,
  reference,
  type = c("branch", "tag", "commit")
) {
  providers <- c(
    "github",
    "bitbucketcloud",
    "azuredevopsservices",
    "githubenterprise",
    "bitbucketserver",
    "gitlab",
    "gitlabenterpriseedition",
    "awscodecommit"
  )

  match.arg(type)
  match.arg(git_provider, providers)

  obj <- list(
    git_url = git_url,
    git_provider = git_provider
  )

  obj[[paste0("git_", type)]] <- reference

  class(obj) <- c("GitSource", "list")
  obj
}

#' Test if object is of class GitSource
#'
#' @param x An object
#' @return `TRUE` if the object inherits from the `GitSource`
#' class.
#' @export
is.git_source <- function(x) {
  inherits(x, "GitSource")
}

#' Notebook Task
#'
#' @param notebook_path The absolute path of the notebook to be run in the
#' Databricks workspace. This path must begin with a slash.
#' @param base_parameters Named list of base parameters to be used for each run
#' of this job.
#'
#' @details
#' If the run is initiated by a call to [db_jobs_run_now()] with parameters
#' specified, the two parameters maps are merged. If the same key is specified
#' in base_parameters and in run-now, the value from run-now is used.
#'
#' Use Task parameter variables to set parameters containing information about
#' job runs.
#'
#' If the notebook takes a parameter that is not specified in the job’s
#' `base_parameters` or the run-now override parameters, the default value from
#' the notebook is used.
#'
#' Retrieve these parameters in a notebook using `dbutils.widgets.get`.
#'
#' @family Task Objects
#'
#' @export
notebook_task <- function(notebook_path, base_parameters = NULL) {
  obj <- list(
    notebook_path = notebook_path,
    base_parameters = base_parameters
  )

  class(obj) <- c("NotebookTask", "JobTask", "list")
  obj
}

#' Test if object is of class NotebookTask
#'
#' @param x An object
#' @return `TRUE` if the object inherits from the `NotebookTask` class.
#' @export
is.notebook_task <- function(x) {
  inherits(x, "NotebookTask")
}


#' Spark Jar Task
#'
#' @param main_class_name The full name of the class containing the main method
#' to be executed. This class must be contained in a JAR provided as a library.
#' The code must use `SparkContext.getOrCreate` to obtain a Spark context;
#' otherwise, runs of the job fail.
#' @param parameters Named list. Parameters passed to the main method. Use Task
#' parameter variables to set parameters containing information about job runs.
#'
#' @family Task Objects
#'
#' @export
spark_jar_task <- function(main_class_name, parameters = list()) {
  obj <- list(
    main_class_name = main_class_name,
    parameters = parameters
  )

  class(obj) <- c("SparkJarTask", "JobTask", "list")
  obj
}

#' Test if object is of class SparkJarTask
#'
#' @param x An object
#' @return `TRUE` if the object inherits from the `SparkJarTask` class.
#' @export
is.spark_jar_task <- function(x) {
  inherits(x, "SparkJarTask")
}


#' Spark Python Task
#'
#' @param python_file The URI of the Python file to be executed. DBFS and S3
#' paths are supported.
#' @param parameters List. Command line parameters passed to the Python file.
#' Use Task parameter variables to set parameters containing information about
#' job runs.
#'
#' @family Task Objects
#'
#' @export
spark_python_task <- function(python_file, parameters = list()) {
  obj <- list(
    python_file = python_file,
    parameters = parameters
  )

  class(obj) <- c("SparkPythonTask", "JobTask", "list")
  obj
}

#' Test if object is of class SparkPythonTask
#'
#' @param x An object
#' @return `TRUE` if the object inherits from the `SparkPythonTask` class.
#' @export
is.spark_python_task <- function(x) {
  inherits(x, "SparkPythonTask")
}


#' Spark Submit Task
#'
#' @param parameters List. Command-line parameters passed to spark submit. Use
#' Task parameter variables to set parameters containing information about job runs.
#'
#' @family Task Objects
#'
#' @export
spark_submit_task <- function(parameters) {
  obj <- list(
    parameters = parameters
  )

  class(obj) <- c("SparkSubmitTask", "JobTask", "list")
  obj
}

#' Test if object is of class SparkSubmitTask
#'
#' @param x An object
#' @return `TRUE` if the object inherits from the `SparkSubmitTask` class.
#' @export
is.spark_submit_task <- function(x) {
  inherits(x, "SparkSubmitTask")
}


#' Pipeline Task
#'
#' @param pipeline_id The full name of the pipeline task to execute.
#'
#' @family Task Objects
#'
#' @export
pipeline_task <- function(pipeline_id) {
  obj <- list(
    pipeline_id = pipeline_id
  )

  class(obj) <- c("PipelineTask", "JobTask", "list")
  obj
}

#' Test if object is of class PipelineTask
#'
#' @param x An object
#' @return `TRUE` if the object inherits from the `PipelineTask` class.
#' @export
is.pipeline_task <- function(x) {
  inherits(x, "PipelineTask")
}


#' Python Wheel Task
#'
#' @param package_name Name of the package to execute.
#' @param entry_point Named entry point to use, if it does not exist in the
#' metadata of the package it executes the function from the package directly
#' using `$packageName.$entryPoint()`.
#' @param parameters Command-line parameters passed to python wheel task.
#'
#' @family Task Objects
#'
#' @export
python_wheel_task <- function(
  package_name,
  entry_point = NULL,
  parameters = list()
) {
  obj <- list(
    package_name = package_name,
    entry_point = entry_point,
    parameters = parameters
  )

  class(obj) <- c("PythonWheelTask", "JobTask", "list")
  obj
}

#' Test if object is of class PythonWheelTask
#'
#' @param x An object
#' @return `TRUE` if the object inherits from the `PythonWheelTask` class.
#' @export
is.python_wheel_task <- function(x) {
  inherits(x, "PythonWheelTask")
}

#' For Each Task
#'
#' @param inputs Array for task to iterate on. This can be a JSON string or a
#' reference to an array parameter.
#' @param task Must be a [job_task()].
#' @param concurrency Maximum allowed number of concurrent runs of the task.
#'
#' @family Task Objects
#'
#' @export
for_each_task <- function(inputs, task, concurrency = 1) {
  stopifnot(is.job_task(task))
  obj <- list(
    inputs = inputs,
    task = task,
    concurrency = concurrency
  )

  class(obj) <- c("ForEachTask", "JobTask", "list")
  obj
}

#' Test if object is of class ForEachTask
#'
#' @param x An object
#' @return `TRUE` if the object inherits from the `ForEachTask` class.
#' @export
is.for_each_task <- function(x) {
  inherits(x, "ForEachTask")
}

#' Condition Task
#'
#' @details
#' The task evaluates a condition that can be used to control the execution of
#' other tasks when the condition_task field is present. The condition task does
#' not require a cluster to execute and does not support retries or notifications.
#'
#' @param left Left operand of the condition task. Either a string value or a
#' job state or parameter reference.
#' @param right Right operand of the condition task. Either a string value or a
#' job state or parameter reference.
#' @param op Operator, one of `"EQUAL_TO"`, `"GREATER_THAN"`,
#' `"GREATER_THAN_OR_EQUAL"`, `"LESS_THAN"`, `"LESS_THAN_OR_EQUAL"`, `"NOT_EQUAL"`
#'
#' @family Task Objects
#'
#' @export
condition_task <- function(
  left,
  right,
  op = c(
    "EQUAL_TO",
    "GREATER_THAN",
    "GREATER_THAN_OR_EQUAL",
    "LESS_THAN",
    "LESS_THAN_OR_EQUAL",
    "NOT_EQUAL"
  )
) {
  op <- match.arg(op)

  obj <- list(
    left = left,
    right = right,
    op = op
  )

  class(obj) <- c("ConditionTask", "JobTask", "list")
  obj
}

#' Test if object is of class ConditionTask
#'
#' @param x An object
#' @return `TRUE` if the object inherits from the `ConditionTask` class.
#' @export
is.condition_task <- function(x) {
  inherits(x, "ConditionTask")
}

#' SQL Query Task
#'
#' @param query_id The canonical identifier of the SQL query.
#' @param warehouse_id The canonical identifier of the SQL warehouse.
#' @param parameters Named list of paramters to be used for each run of this job.
#'
#' @family Task Objects
#'
#' @export
sql_query_task <- function(query_id, warehouse_id, parameters = NULL) {
  obj <- list(
    query = list(query_id = query_id),
    warehouse_id = warehouse_id,
    parameters = parameters
  )

  class(obj) <- c("SqlQueryTask", "JobTask", "list")
  obj
}

#' Test if object is of class SqlQueryTask
#'
#' @param x An object
#' @return `TRUE` if the object inherits from the `SqlQueryTask` class.
#' @export
is.sql_query_task <- function(x) {
  inherits(x, "SqlQueryTask")
}

#' SQL File Task
#'
#' @param path Path of the SQL file. Must be relative if the source is a remote
#' Git repository and absolute for workspace paths.
#' @param source Optional location type of the SQL file. When set to `WORKSPACE`,
#' the SQL file will be retrieved from the local Databricks workspace. When set
#' to `GIT`, the SQL file will be retrieved from a Git repository defined in
#' [`git_source()`] If the value is empty, the task will use `GIT` if
#' [`git_source()`] is defined and `WORKSPACE` otherwise.
#' @param warehouse_id The canonical identifier of the SQL warehouse.
#' @param parameters Named list of paramters to be used for each run of this job.
#'
#' @family Task Objects
#'
#' @export
sql_file_task <- function(
  path,
  warehouse_id,
  source = NULL,
  parameters = NULL
) {
  source <- match.arg(source, choices = c(NULL, "GIT", "WORKSPACE"))

  obj <- list(
    file = list(path = path, source = source),
    warehouse_id = warehouse_id,
    parameters = parameters
  )

  class(obj) <- c("SqlFileTask", "JobTask", "list")
  obj
}

#' Test if object is of class SqlFileTask
#'
#' @param x An object
#' @return `TRUE` if the object inherits from the `SqlFileTask` class.
#' @export
is.sql_file_task <- function(x) {
  inherits(x, "SqlFileTask")
}


#' Run Job Task
#'
#' @param job_id ID of the job to trigger.
#' @param job_parameters Named list, job-level parameters used to trigger job.
#' @param full_refresh If the pipeline should perform a full refresh.
#'
#' @family Task Objects
#'
#' @export
run_job_task <- function(job_id, job_parameters, full_refresh = FALSE) {
  obj <- list(
    job_id = job_id,
    job_parameters = job_parameters,
    pipeline_params = list(full_refresh = full_refresh)
  )

  class(obj) <- c("RunJobTask", "JobTask", "list")
  obj
}

#' Test if object is of class RunJobTask
#'
#' @param x An object
#' @return `TRUE` if the object inherits from the `RunJobTask` class.
#' @export
is.run_job_task <- function(x) {
  inherits(x, "RunJobTask")
}


#' Test if object is of class JobTask
#'
#' @param x An object
#' @return `TRUE` if the object inherits from the `JobTask` class.
#' @export
is.valid_task_type <- function(x) {
  inherits(x, "JobTask")
}


#' Job Tasks
#'
#' @param ... Multiple Instance of tasks [job_task()].
#'
#' @seealso [db_jobs_create()], [db_jobs_reset()], [db_jobs_update()]
#'
#' @export
job_tasks <- function(...) {
  obj <- list(...)

  if (length(obj) == 0) {
    cli::cli_abort("Must specify at least one task")
  }

  # check that all inputs are job tasks
  task_check <- vapply(obj, is.job_task, logical(1))
  stopifnot(all(task_check))

  class(obj) <- c("JobTasks", "list")
  obj
}


#' Job Task
#'
#' @param task_key A unique name for the task. This field is used to refer to
#' this task from other tasks. This field is required and must be unique within
#' its parent job. On [db_jobs_update()] or [db_jobs_reset()], this field is
#' used to reference the tasks to be updated or reset. The maximum length is
#' 100 characters.
#' @param description An optional description for this task. The maximum length
#' is 4096 bytes.
#' @param depends_on Vector of `task_key`'s specifying the dependency graph of
#' the task. All `task_key`'s specified in this field must complete successfully
#' before executing this task. This field is required when a job consists of
#' more than one task.
#' @param existing_cluster_id ID of an existing cluster that is used for all
#' runs of this task.
#' @param new_cluster Instance of [new_cluster()].
#' @param job_cluster_key Task is executed reusing the cluster specified in
#' [db_jobs_create()] with `job_clusters` parameter.
#' @param task One of [notebook_task()], [spark_jar_task()],
#' [spark_python_task()], [spark_submit_task()], [pipeline_task()],
#' [python_wheel_task()].
#' @param libraries Instance of [libraries()].
#' @param email_notifications Instance of [email_notifications].
#' @param timeout_seconds An optional timeout applied to each run of this job
#' task. The default behavior is to have no timeout.
#' @param max_retries An optional maximum number of times to retry an
#' unsuccessful run. A run is considered to be unsuccessful if it completes with
#' the `FAILED` `result_state` or `INTERNAL_ERROR` `life_cycle_state.` The value
#' -1 means to retry indefinitely and the value 0 means to never retry. The
#' default behavior is to never retry.
#' @param min_retry_interval_millis Optional minimal interval in milliseconds
#' between the start of the failed run and the subsequent retry run. The default
#' behavior is that unsuccessful runs are immediately retried.
#' @param retry_on_timeout Optional policy to specify whether to retry a task
#' when it times out. The default behavior is to not retry on timeout.
#' @param run_if The condition determining whether the task is run once its
#' dependencies have been completed.
#'
#' @export
job_task <- function(
  task_key,
  description = NULL,
  depends_on = c(),
  existing_cluster_id = NULL,
  new_cluster = NULL,
  job_cluster_key = NULL,
  task,
  libraries = NULL,
  email_notifications = NULL,
  timeout_seconds = NULL,
  max_retries = 0,
  min_retry_interval_millis = 0,
  retry_on_timeout = FALSE,
  run_if = c(
    "ALL_SUCCESS",
    "ALL_DONE",
    "NONE_FAILED",
    "AT_LEAST_ONE_SUCCESS",
    "ALL_FAILED",
    "AT_LEAST_ONE_FAILED"
  )
) {
  depends_on <- lapply(depends_on, function(x) {
    list(task_key = x)
  })

  run_if <- match.arg(run_if)

  obj <- list(
    task_key = task_key,
    description = description,
    depends_on = depends_on,
    existing_cluster_id = existing_cluster_id,
    new_cluster = new_cluster,
    job_cluster_key = job_cluster_key,
    libraries = libraries,
    email_notifications = email_notifications,
    timeout_seconds = timeout_seconds,
    max_retries = max_retries,
    min_retry_interval_millis = min_retry_interval_millis,
    retry_on_timeout = retry_on_timeout,
    run_if = run_if
  )

  # add task to `obj`, it needs to be named depending on type
  # NOTE: avoiding parsing the class to derive name for now
  task_type <- switch(
    class(task)[1],
    "NotebookTask" = "notebook_task",
    "SparkJarTask" = "spark_jar_task",
    "SparkPythonTask" = "spark_python_task",
    "SparkSubmitTask" = "spark_submit_task",
    "PipelineTask" = "pipeline_task",
    "PythonWheelTask" = "python_wheel_task",
    "ForEachTask" = "for_each_task",
    "ConditionTask" = "condition_task",
    "SqlQueryTask" = "sql_task",
    "SqlFileTask" = "sql_task",
    "RunJobTask" = "run_job_task"
  )

  obj[[task_type]] <- task

  obj <- purrr::discard(obj, is.null)
  class(obj) <- c("JobTaskSettings", "list")
  obj
}

#' Test if object is of class JobTaskSettings
#'
#' @param x An object
#' @return `TRUE` if the object inherits from the `JobTaskSettings` class.
#' @export
is.job_task <- function(x) {
  inherits(x, "JobTaskSettings")
}


#' Embedding Source Column
#'
#' @param name Name of the column
#' @param model_endpoint_name Name of the embedding model endpoint
#'
#' @family Vector Search API
#'
#' @export
embedding_source_column <- function(name, model_endpoint_name) {
  obj <- list(
    name = name,
    embedding_model_endpoint_name = model_endpoint_name
  )

  class(obj) <- c("EmbeddingSourceColumn", "list")
  obj
}

#' Test if object is of class EmbeddingSourceColumn
#'
#' @param x An object
#' @return `TRUE` if the object inherits from the `EmbeddingSourceColumn` class.
#' @export
is.embedding_source_column <- function(x) {
  inherits(x, "EmbeddingSourceColumn")
}

#' Embedding Vector Column
#'
#' @param name Name of the column
#' @param dimension dimension of the embedding vector
#'
#' @family Vector Search API
#'
#' @export
embedding_vector_column <- function(name, dimension) {
  stopifnot(is.numeric(dimension))

  obj <- list(
    name = name,
    embedding_dimension = dimension
  )

  class(obj) <- c("EmbeddingVectorColumn", "list")
  obj
}

#' Test if object is of class EmbeddingVectorColumn
#'
#' @param x An object
#' @return `TRUE` if the object inherits from the `EmbeddingVectorColumn` class.
#' @export
is.embedding_vector_column <- function(x) {
  inherits(x, "EmbeddingVectorColumn")
}


#' Delta Sync Vector Search Index Specification
#'
#' @param source_table The name of the source table.
#' @param embedding_writeback_table Name of table to sync index contents and
#' computed embeddings back to delta table, see details.
#' @param embedding_source_columns The columns that contain the embedding
#' source, must be one or list of [embedding_source_column()]
#' @param embedding_vector_columns The columns that contain the embedding, must
#' be one or list of [embedding_vector_column()]
#' @param pipeline_type Pipeline execution mode, see details.
#'
#' @details
#' `pipeline_type` is either:
#'  - `"TRIGGERED"`:  If the pipeline uses the triggered execution mode, the
#'  system stops processing after successfully refreshing the source table in
#'  the pipeline once, ensuring the table is updated based on the data available
#'  when the update started.
#'  - `"CONTINUOUS"` If the pipeline uses continuous execution, the pipeline
#'  processes new data as it arrives in the source table to keep vector index
#'  fresh.
#'
#' The only supported naming convention for `embedding_writeback_table` is
#' `"<index_name>_writeback_table"`.
#'
#' @seealso [db_vs_indexes_create()]
#' @family Vector Search API
#'
#' @export
delta_sync_index_spec <- function(
  source_table,
  embedding_writeback_table = NULL,
  embedding_source_columns = NULL,
  embedding_vector_columns = NULL,
  pipeline_type = c("TRIGGERED", "CONTINUOUS")
) {
  pipeline_type <- match.arg(pipeline_type)

  # check embedding objects comply
  if (!is.null(embedding_source_columns)) {
    if (
      is.list(embedding_source_columns) &&
        !is.embedding_source_column(embedding_source_columns)
    ) {
      valid_columns <- vapply(
        embedding_source_columns,
        function(x) {
          is.embedding_source_column(x)
        },
        logical(1)
      )
      if (!all(valid_columns)) {
        stop(
          "`embedding_source_columns` must all be defined by `embedding_source_column` function"
        )
      }
    } else {
      stopifnot(is.embedding_source_column(embedding_source_columns))
    }
  }

  if (!is.null(embedding_vector_columns)) {
    if (
      is.list(embedding_vector_columns) &&
        !is.embedding_vector_column(embedding_vector_columns)
    ) {
      valid_columns <- vapply(
        embedding_vector_columns,
        function(x) {
          is.embedding_vector_column(x)
        },
        logical(1)
      )
      if (!all(valid_columns)) {
        stop(
          "`embedding_vector_columns` must all be defined by `embedding_vector_column` function"
        )
      }
    } else {
      stopifnot(is.embedding_vector_column(embedding_vector_columns))
    }
  }

  if (is.null(embedding_vector_columns) & is.null(embedding_source_columns)) {
    cli::cli_abort(
      "Must specify at least one embedding vector or source column"
    )
  }

  obj <- list(
    source_table = source_table,
    embedding_source_columns = embedding_source_columns,
    embedding_vector_columns = embedding_vector_columns,
    embedding_writeback_table = embedding_writeback_table,
    pipeline_type = pipeline_type
  )

  class(obj) <- c("VectorSearchIndexSpec", "DeltaSyncIndex", "list")
  obj
}

#' Delta Sync Vector Search Index Specification
#'
#' @param embedding_source_columns The columns that contain the embedding
#' source, must be one or list of [embedding_source_column()]
#' @param embedding_vector_columns The columns that contain the embedding, must
#' be one or list of [embedding_vector_column()]
#' vectors.
#' @param schema Named list, names are column names, values are types. See
#' details.
#'
#' @details
#' The supported types are:
#'  - `"integer"`
#'  - `"long"`
#'  - `"float"`
#'  - `"double"`
#'  - `"boolean"`
#'  - `"string"`
#'  - `"date"`
#'  - `"timestamp"`
#'  - `"array<float>"`: supported for vector columns
#'  - `"array<double>"`: supported for vector columns
#'
#'
#' @seealso [db_vs_indexes_create()]
#' @family Vector Search API
#'
#' @export
direct_access_index_spec <- function(
  embedding_source_columns = NULL,
  embedding_vector_columns = NULL,
  schema
) {
  # check embedding objects comply
  if (!is.null(embedding_source_columns)) {
    if (
      is.list(embedding_source_columns) &&
        !is.embedding_source_column(embedding_source_columns)
    ) {
      valid_columns <- vapply(
        embedding_source_columns,
        function(x) {
          is.embedding_source_column(x)
        },
        logical(1)
      )
      if (!all(valid_columns)) {
        stop(
          "`embedding_source_columns` must all be defined by `embedding_source_column` function"
        )
      }
    } else {
      stopifnot(is.embedding_source_column(embedding_source_columns))
    }
  }

  if (!is.null(embedding_vector_columns)) {
    if (
      is.list(embedding_vector_columns) &&
        !is.embedding_vector_column(embedding_vector_columns)
    ) {
      valid_columns <- vapply(
        embedding_vector_columns,
        function(x) {
          is.embedding_vector_column(x)
        },
        logical(1)
      )
      if (!all(valid_columns)) {
        stop(
          "`embedding_vector_columns` must all be defined by `embedding_vector_column` function"
        )
      }
    } else {
      stopifnot(is.embedding_vector_column(embedding_vector_columns))
    }
  }

  if (is.null(embedding_vector_columns) & is.null(embedding_source_columns)) {
    cli::cli_abort(
      "Must specify at least one embedding vector or source column"
    )
  }

  if (is.null(schema)) {
    cli::cli_abort("{.arg schema} must be present.")
  }

  if (!(is.list(schema) && rlang::is_named(schema))) {
    cli::cli_abort("{.arg schema} must be a named list.")
  }

  obj <- list(
    schema_json = jsonlite::toJSON(schema, auto_unbox = TRUE),
    embedding_source_columns = embedding_source_columns,
    embedding_vector_columns = embedding_vector_columns
  )

  class(obj) <- c("VectorSearchIndexSpec", "DirectAccessIndex", "list")
  obj
}


#' Test if object is of class VectorSearchIndexSpec
#'
#' @param x An object
#' @return `TRUE` if the object inherits from the `VectorSearchIndexSpec` class.
#' @export
is.vector_search_index_spec <- function(x) {
  inherits(x, "VectorSearchIndexSpec")
}


#' Test if object is of class DirectAccessIndex
#'
#' @param x An object
#' @return `TRUE` if the object inherits from the `DirectAccessIndex` class.
#' @export
is.direct_access_index <- function(x) {
  inherits(x, "DirectAccessIndex")
}


#' Test if object is of class DeltaSyncIndex
#'
#' @param x An object
#' @return `TRUE` if the object inherits from the `DeltaSyncIndex` class.
#' @export
is.delta_sync_index <- function(x) {
  inherits(x, "DeltaSyncIndex")
}
