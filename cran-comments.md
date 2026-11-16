## Test environment

* macOS Tahoe 26.7.2 (aarch64), R 4.5.1

## R CMD check results

0 errors | 0 warnings | 0 notes

Checked `brickster_0.2.16.tar.gz` with `--as-cran --run-donttest`, including
tests, vignettes and the manual. All suggested packages were installed,
including Arrow 22.0.0 with zstd support.

Both offline and normal `testthat::test_local()` runs passed with 1,721
expectations. Authenticated integration tests were skipped because workspace
credentials and a test staging volume were unavailable.

R-devel, Windows and authenticated runtime validation are pending repository CI.

## Reverse dependencies

`connector.databricks` 0.2.0 was checked against brickster 0.2.16:
0 errors | 0 warnings | 0 notes. Its authenticated tests were skipped.
CRAN incoming submission eligibility checks were disabled for this
already-published reverse-dependency archive.
