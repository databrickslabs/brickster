# Databricks Request Helper

Databricks Request Helper

## Usage

``` r
db_request(endpoint, method, version = NULL, body = NULL, host, token, ...)
```

## Arguments

- endpoint:

  Databricks REST API Endpoint

- method:

  Passed to
  [`httr2::req_method()`](https://httr2.r-lib.org/reference/req_method.html)

- version:

  String, API version of endpoint. E.g. `2.0`.

- body:

  Named list, passed to
  [`httr2::req_body_json()`](https://httr2.r-lib.org/reference/req_body.html).

- host:

  Databricks host, defaults to
  [`db_host()`](https://databrickslabs.github.io/brickster/reference/db_host.md).

- token:

  Databricks token, defaults to
  [`db_token()`](https://databrickslabs.github.io/brickster/reference/db_token.md).

- ...:

  Parameters passed on to
  [`httr2::req_body_json()`](https://httr2.r-lib.org/reference/req_body.html)
  when `body` is not `NULL`.

## Value

request

## See also

Other Request Helpers:
[`db_perform_request()`](https://databrickslabs.github.io/brickster/reference/db_perform_request.md),
[`db_req_error_body()`](https://databrickslabs.github.io/brickster/reference/db_req_error_body.md),
[`db_request_json()`](https://databrickslabs.github.io/brickster/reference/db_request_json.md)
