# Wheel Library (Python)

Wheel Library (Python)

## Usage

``` r
lib_whl(whl)
```

## Arguments

- whl:

  URI of the wheel or zipped wheels to be installed. DBFS and S3 URIs
  are supported. For example: `dbfs:/my/whl` or `s3://my-bucket/whl`. If
  S3 is used, make sure the cluster has read access on the library. You
  may need to launch the cluster with an instance profile to access the
  S3 URI. Also the wheel file name needs to use the correct convention.
  If zipped wheels are to be installed, the file name suffix should be
  `.wheelhouse.zip`.

## See also

[`libraries()`](https://databrickslabs.github.io/brickster/reference/libraries.md)

Other Library Objects:
[`lib_cran()`](https://databrickslabs.github.io/brickster/reference/lib_cran.md),
[`lib_egg()`](https://databrickslabs.github.io/brickster/reference/lib_egg.md),
[`lib_jar()`](https://databrickslabs.github.io/brickster/reference/lib_jar.md),
[`lib_maven()`](https://databrickslabs.github.io/brickster/reference/lib_maven.md),
[`lib_pypi()`](https://databrickslabs.github.io/brickster/reference/lib_pypi.md),
[`libraries()`](https://databrickslabs.github.io/brickster/reference/libraries.md)
