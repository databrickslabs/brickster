db_feature_tables_search <- function(filter = NULL,
                                     max_results = 100,
                                     page_token = NULL,
                                     host = db_host(), token = db_token(),
                                     perform_request = TRUE) {

  body <- list(
    text = filter,
    max_results = max_results,
    page_token = page_token
  )

  req <- db_request(
    endpoint = "feature-store/feature-tables/search",
    method = "GET",
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


db_feature_tables_get <- function(feature_table,
                                  host = db_host(), token = db_token(),
                                  perform_request = TRUE) {

  req <- db_request(
    endpoint = "feature-store/feature-tables/get",
    method = "GET",
    version = "2.0",
    host = host,
    token = token
  ) %>%
    httr2::req_url_query(name = feature_table)

  if (perform_request) {
    db_perform_request(req)$feature_table
  } else {
    req
  }

}

db_feature_table_features <- function(feature_table,
                                  host = db_host(), token = db_token(),
                                  perform_request = TRUE) {

  req <- db_request(
    endpoint = "feature-store/features/get",
    method = "GET",
    version = "2.0",
    host = host,
    token = token
  ) %>%
    httr2::req_url_query(feature_table = feature_table)

  if (perform_request) {
    db_perform_request(req)$features
  } else {
    req
  }

}




table <- "ab_data_an.churn_features"
