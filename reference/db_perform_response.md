# Perform Databricks API Request and Return Response

Perform Databricks API Request and Return Response

## Usage

``` r
db_perform_response(req, ...)
```

## Arguments

- req:

  `{httr2}` request.

- ...:

  Parameters passed to
  [`httr2::req_perform()`](https://httr2.r-lib.org/reference/req_perform.html)

## See also

Other Request Helpers:
[`db_perform_request()`](https://databrickslabs.github.io/brickster/reference/db_perform_request.md),
[`db_req_error_body()`](https://databrickslabs.github.io/brickster/reference/db_req_error_body.md),
[`db_request()`](https://databrickslabs.github.io/brickster/reference/db_request.md),
[`db_request_json()`](https://databrickslabs.github.io/brickster/reference/db_request_json.md)
