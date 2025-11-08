# Egg Library (Python)

Egg Library (Python)

## Usage

``` r
lib_egg(egg)
```

## Arguments

- egg:

  URI of the egg to be installed. DBFS and S3 URIs are supported. For
  example: `dbfs:/my/egg` or `s3://my-bucket/egg`. If S3 is used, make
  sure the cluster has read access on the library. You may need to
  launch the cluster with an instance profile to access the S3 URI.

## See also

[`libraries()`](https://databrickslabs.github.io/brickster/reference/libraries.md)

Other Library Objects:
[`lib_cran()`](https://databrickslabs.github.io/brickster/reference/lib_cran.md),
[`lib_jar()`](https://databrickslabs.github.io/brickster/reference/lib_jar.md),
[`lib_maven()`](https://databrickslabs.github.io/brickster/reference/lib_maven.md),
[`lib_pypi()`](https://databrickslabs.github.io/brickster/reference/lib_pypi.md),
[`lib_whl()`](https://databrickslabs.github.io/brickster/reference/lib_whl.md),
[`libraries()`](https://databrickslabs.github.io/brickster/reference/libraries.md)
