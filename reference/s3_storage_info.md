# S3 Storage Info

S3 Storage Info

## Usage

``` r
s3_storage_info(
  destination,
  region = NULL,
  endpoint = NULL,
  enable_encryption = FALSE,
  encryption_type = c("sse-s3", "sse-kms"),
  kms_key = NULL,
  canned_acl = NULL
)
```

## Arguments

- destination:

  S3 destination. For example: `s3://my-bucket/some-prefix`. You must
  configure the cluster with an instance profile and the instance
  profile must have write access to the destination. **You cannot use
  AWS keys**.

- region:

  S3 region. For example: `us-west-2`. Either region or endpoint must be
  set. If both are set, endpoint is used.

- endpoint:

  S3 endpoint. For example: `https://s3-us-west-2.amazonaws.com`. Either
  region or endpoint must be set. If both are set, endpoint is used.

- enable_encryption:

  Boolean (Default: `FALSE`). If `TRUE` Enable server side encryption.

- encryption_type:

  Encryption type, it could be `sse-s3` or `sse-kms`. It is used only
  when encryption is enabled and the default type is `sse-s3`.

- kms_key:

  KMS key used if encryption is enabled and encryption type is set to
  `sse-kms`.

- canned_acl:

  Set canned access control list. For example:
  `bucket-owner-full-control`. If `canned_acl` is set, the cluster
  instance profile must have `s3:PutObjectAcl` permission on the
  destination bucket and prefix. The full list of possible canned ACLs
  can be found in
  [docs](https://docs.aws.amazon.com/AmazonS3/latest/userguide/acl-overview.html#canned-acl).
  By default only the object owner gets full control. If you are using
  cross account role for writing data, you may want to set
  `bucket-owner-full-control` to make bucket owner able to read the
  logs.

## See also

[`cluster_log_conf()`](https://databrickslabs.github.io/brickster/reference/cluster_log_conf.md),
[`init_script_info()`](https://databrickslabs.github.io/brickster/reference/init_script_info.md)

Other Cluster Log Configuration Objects:
[`cluster_log_conf()`](https://databrickslabs.github.io/brickster/reference/cluster_log_conf.md),
[`dbfs_storage_info()`](https://databrickslabs.github.io/brickster/reference/dbfs_storage_info.md)

Other Init Script Info Objects:
[`dbfs_storage_info()`](https://databrickslabs.github.io/brickster/reference/dbfs_storage_info.md),
[`file_storage_info()`](https://databrickslabs.github.io/brickster/reference/file_storage_info.md)
