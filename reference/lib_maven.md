# Maven Library (Scala)

Maven Library (Scala)

## Usage

``` r
lib_maven(coordinates, repo = NULL, exclusions = NULL)
```

## Arguments

- coordinates:

  Gradle-style Maven coordinates. For example: `org.jsoup:jsoup:1.7.2`.

- repo:

  Maven repo to install the Maven package from. If omitted, both Maven
  Central Repository and Spark Packages are searched.

- exclusions:

  List of dependencies to exclude. For example:
  `list("slf4j:slf4j", "*:hadoop-client")`. [Maven dependency
  exclusions](https://maven.apache.org/guides/introduction/introduction-to-optional-and-excludes-dependencies.html).

## See also

[`libraries()`](https://databrickslabs.github.io/brickster/reference/libraries.md)

Other Library Objects:
[`lib_cran()`](https://databrickslabs.github.io/brickster/reference/lib_cran.md),
[`lib_egg()`](https://databrickslabs.github.io/brickster/reference/lib_egg.md),
[`lib_jar()`](https://databrickslabs.github.io/brickster/reference/lib_jar.md),
[`lib_pypi()`](https://databrickslabs.github.io/brickster/reference/lib_pypi.md),
[`lib_whl()`](https://databrickslabs.github.io/brickster/reference/lib_whl.md),
[`libraries()`](https://databrickslabs.github.io/brickster/reference/libraries.md)
