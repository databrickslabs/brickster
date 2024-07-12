#' List Vector Search Endpoints
#'
#' @param page_token Token for pagination
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @family Vector Search API
#'
#' @export
db_vs_endpoints_list <- function(page_token = NULL,
                                 host = db_host(), token = db_token(),
                                 perform_request = TRUE) {

  req <- db_request(
    endpoint = "vector-search/endpoints",
    method = "GET",
    version = "2.0",
    host = host,
    token = token
  )

  req <- req %>%
    httr2::req_url_query(
      page_token = page_token
    )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }

}

#' Get a Vector Search Endpoint
#'
#' @param endpoint Name of vector search endpoint
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @family Vector Search API
#'
#' @export
db_vs_endpoints_get <- function(endpoint,
                                host = db_host(), token = db_token(),
                                perform_request = TRUE) {

  req <- db_request(
    endpoint = paste0("vector-search/endpoints/", endpoint),
    method = "GET",
    version = "2.0",
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }

}

#' Create a Vector Search Endpoint
#'
#' @param name Name of vector search endpoint
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' This function can take a few moments to run.
#'
#'
#' @family Vector Search API
#'
#' @export
db_vs_endpoints_create <- function(name,
                                   host = db_host(), token = db_token(),
                                   perform_request = TRUE) {

  body <- list(
    name = name,
    endpoint_type = "STANDARD"
  )

  req <- db_request(
    endpoint = "vector-search/endpoints",
    method = "POST",
    version = "2.0",
    body = body,
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }

}

#' Delete a Vector Search Endpoint
#'
#' @param endpoint Name of vector search endpoint
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @family Vector Search API
#'
#' @export
db_vs_endpoints_delete <- function(endpoint,
                                   host = db_host(), token = db_token(),
                                   perform_request = TRUE) {

  req <- db_request(
    endpoint = paste0("vector-search/endpoints/", endpoint),
    method = "DELETE",
    version = "2.0",
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)
    TRUE
  } else {
    req
  }

}

#' List Vector Search Indexes
#'
#' @param endpoint Name of vector search endpoint
#' @param page_token `page_token` returned from prior query
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @family Vector Search API
#'
#' @export
db_vs_indexes_list <- function(endpoint, page_token = NULL,
                               host = db_host(), token = db_token(),
                               perform_request = TRUE) {

  req <- db_request(
    endpoint = "vector-search/indexes",
    method = "GET",
    version = "2.0",
    host = host,
    token = token
  )

  req <- req %>%
    httr2::req_url_query(
      endpoint_name = endpoint,
      page_token = page_token
    )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }

}


#' Get a Vector Search Index
#'
#' @param index Name of vector search index
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @family Vector Search API
#'
#' @export
db_vs_indexes_get <- function(index,
                              host = db_host(), token = db_token(),
                              perform_request = TRUE) {

  req <- db_request(
    endpoint = paste0("vector-search/indexes/", index),
    method = "GET",
    version = "2.0",
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }

}

#' Create a Vector Search Index
#'
#' @param name Name of vector search index
#' @param endpoint Name of vector search endpoint
#' @param primary_key Vector search primary key column name
#' @param spec
#'
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @family Vector Search API
#'
#' @export
db_vs_indexes_create <- function(name, endpoint, primary_key, spec,
                                 host = db_host(), token = db_token(),
                                 perform_request = TRUE) {


  stopifnot(is.vector_search_index_spec(spec))

  delta_sync_index_spec <- NULL
  direct_access_index_spec <- NULL

  if (is.delta_sync_index(spec)) {
    index_type <- "DELTA_SYNC"
    delta_sync_index_spec <- spec
  } else if (is.direct_access_index(spec)) {
    index_type <- "DIRECT_ACCESS"
    direct_access_index_spec <- spec
  } else {
    stop("`spec` is invalid type, must be defined by either `delta_sync_index_spec()` or `direct_access_index_spec()`")
  }

  body <- list(
    name = name,
    endpoint_name = endpoint,
    primary_key = primary_key,
    index_type = index_type,
    delta_sync_index_spec = delta_sync_index_spec,
    direct_access_index_spec = direct_access_index_spec
  )

  req <- db_request(
    endpoint = "vector-search/indexes",
    method = "POST",
    version = "2.0",
    body = body,
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }

}

#' Delete a Vector Search Index
#'
#' @param index Name of vector search index
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @family Vector Search API
#'
#' @export
db_vs_indexes_delete <- function(index,
                                 host = db_host(), token = db_token(),
                                 perform_request = TRUE) {

  req <- db_request(
    endpoint = paste0("vector-search/indexes/", index),
    method = "DELETE",
    version = "2.0",
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }

}



#' Query a Vector Search Index
#'
#' @param index Name of vector search index
#' @param columns Column names to include in response
#' @param filters_json JSON string representing query filters, see details.
#' @param query_vector Numeric vector. Required for direct vector access index
#' and delta sync index using self managed vectors.
#' @param query_text Required for delta sync index using model endpoint.
#' @param score_threshold Numeric score threshold for the approximate nearest
#' neighbour (ANN) search. Defaults to 0.0.
#' @param query_type One of `ANN` (default) or `HYBRID`
#' @param num_results Number of returns to return (default: 10).
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' You cannot specify both `query_vector` and `query_text` at the same time.
#'
#' `filter_jsons` examples:
#'  - `'{"id <": 5}'`: Filter for id less than 5
#'  - `'{"id >": 5}'`: Filter for id greater than 5
#'  - `'{"id <=": 5}'`: Filter for id less than equal to 5
#'  - `'{"id >=": 5}'`: Filter for id greater than equal to 5
#'  - `'{"id": 5}'`: Filter for id equal to 5
#'  - `'{"id": 5, "age >=": 18}'`: Filter for id equal to 5 and age greater than
#'  equal to 18
#'
#'  `filter_jsons` will convert attempt to use `jsonlite::toJSON` on any
#'  non character vectors.
#'
#' Refer to docs for [Vector Search](https://docs.databricks.com/en/generative-ai/create-query-vector-search.html#use-filters-on-queries).
#'
#' @family Vector Search API
#' @examples
#' \dontrun{
#' db_vs_indexes_sync(
#'   index = "myindex",
#'   columns = c("id", "text"),
#'   query_vector = c(1, 2, 3)
#' )
#' }
#'
#' @export
db_vs_indexes_query <- function(index, columns, filters_json,
                                query_vector = NULL,
                                query_text = NULL,
                                score_threshold = 0,
                                query_type = c("ANN", "HYBRID"),
                                num_results = 10,
                                host = db_host(), token = db_token(),
                                perform_request = TRUE) {

  query_type <- match.arg(query_type)

  body <- list(
    columns = columns,
    filters_json = filters_json,
    query_vector = query_vector,
    query_text = query_text,
    query_type = query_type,
    num_results = num_results
  )

  req <- db_request(
    endpoint = paste0("vector-search/indexes/", index, "/query"),
    method = "POST",
    version = "2.0",
    body = body,
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }

}

#' Query Vector Search Next Page
#'
#' @param index Name of vector search index
#' @param endpoint Name of vector search endpoint
#' @param page_token `page_token` returned from prior query
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @family Vector Search API
#'
#' @export
db_vs_indexes_query_next_page <- function(index, endpoint,
                                          page_token = NULL,
                                          host = db_host(), token = db_token(),
                                          perform_request = TRUE) {

  body <- list(
    endpoint_name = endpoint,
    page_token = page_token
  )

  req <- db_request(
    endpoint = paste0("vector-search/indexes/", index, "/query-next-page"),
    method = "POST",
    version = "2.0",
    body = body,
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }

}


#' Synchronize a Vector Search Index
#'
#' @param index Name of vector search index
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' Triggers a synchronization process for a specified vector index. The index
#' must be a 'Delta Sync' index.
#'
#'
#' @family Vector Search API
#'
#' @export
db_vs_indexes_sync <- function(index,
                               host = db_host(), token = db_token(),
                               perform_request = TRUE) {

  req <- db_request(
    endpoint = paste0("vector-search/indexes/", index, "/sync"),
    method = "POST",
    version = "2.0",
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)
    TRUE
  } else {
    req
  }

}


#' Scan a Vector Search Index
#'
#' @param endpoint Name of vector search endpoint to scan
#' @param index Name of vector search index to scan
#' @param num_results Number of returns to return (default: 10)
#' @param last_primary_key Primary key of the last entry returned in previous
#' scan
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' Scan the specified vector index and return the first `num_results` entries
#' after the exclusive `primary_key`.
#'
#' @family Vector Search API
#'
#' @export
db_vs_indexes_scan <- function(endpoint, index,
                               last_primary_key, num_results = 10,
                               host = db_host(), token = db_token(),
                               perform_request = TRUE) {

  body <- list(
    num_results = num_results,
    endpoint_name = endpoint,
    last_primary_key = last_primary_key
  )

  req <- db_request(
    endpoint = paste0("vector-search/indexes/", index, "/scan"),
    method = "POST",
    version = "2.0",
    body = body,
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }

}


#' Upsert Data into a Vector Search Index
#'
#' @param index Name of vector search index
#' @param df data.frame containing data to upsert
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @family Vector Search API
#'
#' @export
db_vs_indexes_upsert_data <- function(index, df,
                                      host = db_host(), token = db_token(),
                                      perform_request = TRUE) {

  body <- list(
    inputs_json = jsonlite::toJSON(x = df, auto_unbox = TRUE)
  )

  req <- db_request(
    endpoint = paste0("vector-search/indexes/", index, "/upsert-data"),
    method = "POST",
    version = "2.0",
    body = body,
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }

}


#' Delete Data from a Vector Search Index
#'
#' @param index Name of vector search index
#' @param primary_keys primary keys to be deleted from index
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @family Vector Search API
#'
#' @export
db_vs_indexes_delete_data <- function(index, primary_keys,
                                      host = db_host(), token = db_token(),
                                      perform_request = TRUE) {

  body <- list(
    primary_keys = primary_keys
  )

  req <- db_request(
    endpoint = paste0("vector-search/indexes/", index, "/delete-data"),
    method = "DELETE",
    version = "2.0",
    body = body,
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }

}

