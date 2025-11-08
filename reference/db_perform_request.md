# Perform Databricks API Request

Perform Databricks API Request

## Usage

``` r
db_perform_request(req, ...)
```

## Arguments

- req:

  `{httr2}` request.

- ...:

  Parameters passed to
  [`httr2::resp_body_json()`](https://httr2.r-lib.org/reference/resp_body_raw.html)

## See also

Other Request Helpers:
[`db_req_error_body()`](https://databrickslabs.github.io/brickster/reference/db_req_error_body.md),
[`db_request()`](https://databrickslabs.github.io/brickster/reference/db_request.md),
[`db_request_json()`](https://databrickslabs.github.io/brickster/reference/db_request_json.md)
