# dbplyr Backend for Databricks SQL

This file implements dbplyr backend support for Databricks SQL
warehouses, enabling dplyr syntax to be translated to Databricks SQL.

## Details

[`cumprod()`](https://rdrr.io/r/base/cumsum.html) returns cumulative
products as doubles and propagates SQL `NULL` values to subsequent rows
in the group. Use
[`dbplyr::window_order()`](https://dbplyr.tidyverse.org/reference/window_order.html)
with a unique ordering (including a tie-breaker where needed) for
reproducible results. The translation collects and multiplies each
cumulative prefix, so large partitions can be expensive.
