db_experiments_list <- function(view_type = c("ACTIVE_ONLY", "DELETED_ONLY", "ALL"),
                                max_results = 1000,
                                page_token = NULL,
                                host = db_host(), token = db_token(),
                                perform_request = TRUE) {

  view_type <- match.arg(view_type)

  body <- list(
    view_type = view_type,
    max_results = max_results,
    page_token = page_token
  )

  req <- db_request(
    endpoint = "mlflow/experiments/list",
    method = "GET",
    version = "2.0",
    body = body,
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)$experiments
  } else {
    req
  }
}

db_experiments_get <- function(name = NULL, id = NULL,
                                host = db_host(), token = db_token(),
                                perform_request = TRUE) {

  if (!is.null(name) && !is.null(id)) {
    cli::cli_abort("Specify {.arg name} or {.arg id}, not both.")
  }

  body <- list()
  if (!is.null(name)) {
    body$experiment_name <- name
    endpoint_suffix <- "get-by-name"
  }

  if (!is.null(id)) {
    body$experiment_id <- id
    endpoint_suffix <- "get"
  }

  req <- db_request(
    endpoint = "mlflow/experiments",
    method = "GET",
    version = "2.0",
    body = body,
    host = host,
    token = token
  ) |>
    httr2::req_url_path_append(endpoint_suffix)

  if (perform_request) {
    db_perform_request(req)$experiment
  } else {
    req
  }
}

