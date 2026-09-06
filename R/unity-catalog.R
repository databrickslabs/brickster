db_uc_metastore_summary <- function(host = db_host(), token = db_token(),
                                    perform_request = TRUE) {

  req <- db_request(
    endpoint = "unity-catalog/metastore_summary",
    method = "GET",
    version = "2.1",
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }
}

db_uc_storage_creds_list <- function(host = db_host(), token = db_token(),
                                    perform_request = TRUE) {

  req <- db_request(
    endpoint = "unity-catalog/storage-credentials",
    method = "GET",
    version = "2.1",
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }
}


db_uc_storage_creds_get <- function(name,
                                    host = db_host(), token = db_token(),
                                    perform_request = TRUE) {

  body <- list(
    name = name
  )

  req <- db_request(
    endpoint = "unity-catalog/storage-credentials",
    method = "GET",
    version = "2.1",
    body = body,
    host = host,
    token = token
  ) |>
    httr2::req_url_path_append(name)

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }
}

db_uc_external_loc_list <- function(host = db_host(), token = db_token(),
                                     perform_request = TRUE) {

  req <- db_request(
    endpoint = "unity-catalog/external-locations",
    method = "GET",
    version = "2.1",
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }
}


db_uc_external_loc_get <- function(name,
                                    host = db_host(), token = db_token(),
                                    perform_request = TRUE) {


  req <- db_request(
    endpoint = "unity-catalog/external-locations/",
    method = "GET",
    version = "2.1",
    host = host,
    token = token
  ) |>
    httr2::req_url_path_append(name)

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }
}




db_uc_models_list <- function(catalog, schema,
                              host = db_host(), token = db_token(),
                              perform_request = TRUE, page_token = NULL) {

  stopifnot(is.null(page_token) || (is.character(page_token) &&
    length(page_token) == 1L && !is.na(page_token) && nzchar(page_token)))

  req <- db_request(
    endpoint = "unity-catalog/models",
    method = "GET",
    version = "2.1",
    host = host,
    token = token
  ) |>
    httr2::req_url_query(
      catalog_name = catalog,
      schema_name = schema,
      include_browse = 'true',
      page_token = page_token
    )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }
}


db_uc_models_get <- function(catalog, schema, model,
                             host = db_host(), token = db_token(),
                             perform_request = TRUE) {

  req <- db_request(
    endpoint = "unity-catalog/models",
    method = "GET",
    version = "2.1",
    host = host,
    token = token
  ) |>
    httr2::req_url_path_append(paste(catalog, schema, model, sep = ".")) |>
    httr2::req_url_query(include_aliases = 'true')

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }
}


db_uc_model_versions_get <- function(catalog, schema, model,
                             host = db_host(), token = db_token(),
                             perform_request = TRUE, page_token = NULL) {

  stopifnot(is.null(page_token) || (is.character(page_token) &&
    length(page_token) == 1L && !is.na(page_token) && nzchar(page_token)))

  req <- db_request(
    endpoint = "unity-catalog/models",
    method = "GET",
    version = "2.1",
    host = host,
    token = token
  ) |>
    httr2::req_url_path_append(paste(catalog, schema, model, sep = ".")) |>
    httr2::req_url_path_append("versions") |>
    httr2::req_url_query(max_results = 1000, page_token = page_token)

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }
}

db_uc_funcs_list <- function(catalog, schema,
                              host = db_host(), token = db_token(),
                              perform_request = TRUE, page_token = NULL) {

  stopifnot(is.null(page_token) || (is.character(page_token) &&
    length(page_token) == 1L && !is.na(page_token) && nzchar(page_token)))

  req <- db_request(
    endpoint = "unity-catalog/functions",
    method = "GET",
    version = "2.1",
    host = host,
    token = token
  ) |>
    httr2::req_url_query(
      catalog_name = catalog,
      schema_name = schema,
      max_results = 0,
      page_token = page_token
    )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }
}


db_uc_funcs_get <- function(catalog, schema, func,
                             host = db_host(), token = db_token(),
                             perform_request = TRUE) {

  req <- db_request(
    endpoint = "unity-catalog/functions",
    method = "GET",
    version = "2.1",
    host = host,
    token = token
  ) |>
    httr2::req_url_path_append(paste(catalog, schema, func, sep = "."))

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }
}


# Collect single-page UC responses for connection-pane workflows.
db_uc_list_all_pages <- function(list_page, field, ...) {
  pages <- list()
  page_token <- NULL
  seen_tokens <- character()
  repeat {
    page <- list_page(..., page_token = page_token)
    pages[[length(pages) + 1L]] <- page[[field]] %||% list()
    page_token <- page$next_page_token
    if (is.null(page_token) || !nzchar(page_token)) break
    if (page_token %in% seen_tokens) {
      cli::cli_abort("Unity Catalog listing returned a repeated page token for {.val {field}}.")
    }
    seen_tokens <- c(seen_tokens, page_token)
  }
  purrr::list_flatten(pages)
}
