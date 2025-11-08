# Add Library Path

Add Library Path

## Usage

``` r
add_lib_path(path, after, version = FALSE)
```

## Arguments

- path:

  Directory that will added as location for which packages are searched.
  Recursively creates the directory if it doesn't exist. On Databricks
  remember to use `/dbfs/` or `/Volumes/...` as a prefix.

- after:

  Location at which to append the `path` value after.

- version:

  If `TRUE` will add the R version string to the end of `path`. This is
  recommended if using different R versions and sharing a common `path`
  between users.

## Details

This functions primary use is when using Databricks notebooks or hosted
RStudio, however, it works anywhere.

## See also

[`base::.libPaths()`](https://rdrr.io/r/base/libPaths.html),
[`remove_lib_path()`](https://databrickslabs.github.io/brickster/reference/remove_lib_path.md)
