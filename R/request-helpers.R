# request helpers

#' Databricks Request Helper
#'
#' @param endpoint Databricks REST API Endpoint
#' @param method Passed to [httr2::req_method()]
#' @param version String, API version of endpoint. E.g. `2.0`.
#' @param body Named list, passed to [httr2::req_body_json()].
#' @param host Databricks host, defaults to [db_host()].
#' @param token Databricks token, defaults to [db_token()].
#' @param ... Parameters passed on to [httr2::req_body_json()] when `body` is not `NULL`.
#'
#' @family Request Helpers
#'
#' @return request
#' @import httr2
#' @importFrom magrittr `%>%`
db_request <- function(endpoint, method, version = NULL, body = NULL, host, token, ...) {

  # if (ajax) {
  #   api <- "ajax-api"
  #   host <- paste0(host, "?o=", wsid)
  # } else {
  #   api <- "api"
  # }
  api <- "api"

  req <- httr2::request(base_url = paste0(host, api, "/", version, "/")) %>%
    httr2::req_auth_bearer_token(token) %>%
    httr2::req_user_agent(string = "brickster") %>%
    httr2::req_url_path_append(endpoint) %>%
    httr2::req_method(method)

  if (!is.null(body)) {
    body <- base::Filter(length, body)
    req <- req %>%
      httr2::req_body_json(body, ...)
  }

  req

}


#' Propagate Databricks API Errors
#'
#' @param resp Object with class `httr2_response`.
#'
#' @family Request Helpers
db_req_error_body <- function(resp) {
  json <- resp %>% httr2::resp_body_json()
  # if there is "message":
  if ("message" %in% names(json)) {
    paste(json$error_code, json$message, sep = ": ")
  } else if (length(json) == 1) {
    json[[1]]
  } else {
    paste(json, collapse = " ")
  }
}

#' Perform Databricks API Request
#'
#' @param req `{httr2}` request.
#' @param ... Parameters passed to [httr2::resp_body_json()]
#'
#' @family Request Helpers
db_perform_request <- function(req, ...) {
  req %>%
    httr2::req_error(body = db_req_error_body) %>%
    httr2::req_perform() %>%
    httr2::resp_body_json(...)
}

#' Generate Request JSON
#'
#' @param req a httr2 request, ideally from [db_request()].
#'
#' @return JSON string
#'
#' @family Request Helpers
#' @export
db_request_json <- function(req) {
  if (!is.null(req$body)) {
    # request specifies toJSON parameters
    opts <- req$body$params
    jsonlite::toJSON(
      x = req$body$data,
      null = opts$null,
      digits = opts$digits,
      auto_unbox = opts$auto_unbox
    )
  } else {
    NULL
  }
}

