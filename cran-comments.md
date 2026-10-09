## Resubmission

The Debian pretest reported four test failures because Arrow was built without
zstd support. Tests that write zstd-compressed Parquet now check
`arrow::codec_is_available("zstd")` and skip when it is unavailable.
Volume staging continues to require zstd; runtime behavior is unchanged.

## Test environment

* macOS Tahoe 26.6.2 (aarch64), R 4.5.1

## R CMD check results

0 errors | 0 warnings | 0 notes

Checked with `--as-cran --run-donttest`, including tests, vignettes and the manual.
Authenticated integration tests are skipped without workspace credentials.
The full test suite passes with zstd available and with codec availability
mocked as unavailable; only the four zstd-dependent offline tests additionally skip.

## Reverse dependencies

`connector.databricks` 0.1.0 was checked against brickster 0.2.15:
0 errors | 0 warnings | 0 notes. Its authenticated tests were skipped.
CRAN incoming submission eligibility checks were disabled for this
already-published reverse-dependency archive.
