#' Generate Database Credential
#'
#' @param permission_set Permission set for the credential request. Currently
#' only `READ_ONLY` is supported.
#' @param tables Optional character vector of table names to scope the
#' credential to.
#' @param instance_names Character vector of database instance names to scope
#' the credential to.
#'
#' @details
#' An idempotency token is generated automatically for each request (UUID4-like
#' string).
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @family Database API
#'
#' @returns List
#' @export
db_lakebase_creds_generate <- function(
  instance_names,
  tables = NULL,
  permission_set = "READ_ONLY",
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  permission_set <- match.arg(permission_set)
  stopifnot(!is.null(instance_names), length(instance_names) > 0)

  resources <- NULL
  if (!is.null(tables)) {
    resources <- lapply(tables, function(tbl) {
      list(table_name = tbl)
    })
  }

  # generate a UUID-like request id for idempotency
  rand_hex <- function(n) paste(sample(c(0:9, letters[1:6]), n, replace = TRUE), collapse = "")
  request_id <- paste(
    rand_hex(8),
    rand_hex(4),
    rand_hex(4),
    rand_hex(4),
    rand_hex(12),
    sep = "-"
  )

  claims <- list(
    list(
      permission_set = permission_set,
      resources = resources
    )
  )

  body <- list(
    claims = claims,
    instance_names = instance_names,
    request_id = request_id
  )

  req <- db_request(
    endpoint = "database/credentials",
    method = "POST",
    version = "2.0",
    host = host,
    token = token,
    body = body
  )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }
}


#' List Database Instances
#'
#' @param page_size Maximum number of instances to return in a single page.
#' @param page_token Pagination token to retrieve the next page of results.
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @family Database API
#'
#' @examples
#' \dontrun{
#' library(brickster)
#' library(DBI)
#' library(RPostgres)
#'
#' # list all lakebase instances
#' dbs <- db_lakebase_list()
#'
#' # connect to the first instance available using {RPostgres}
#' # using identity that brickster is running as generate a token
#' creds <- db_lakebase_creds_generate(instance_names = dbs[[1]]$name)
#'
#' con <- dbConnect(
#'   drv = RPostgres::Postgres(),
#'   host = dbs[[1]]$read_write_dns,
#'   user = db_current_user()$userName,
#'   password = creds$token,
#'   dbname = "databricks_postgres",
#'   sslmode = "require"
#' )
#'
#' dbListTables(con)
#' }
#'
#' @returns List
#' @export
db_lakebase_list <- function(
  page_size = 50,
  page_token = NULL,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  req <- db_request(
    endpoint = "database/instances",
    method = "GET",
    version = "2.0",
    host = host,
    token = token
  ) |>
    httr2::req_url_query(
      page_size = page_size,
      page_token = page_token
    )

  if (perform_request) {
    db_perform_request(req) |> purrr::flatten()
  } else {
    req
  }
}


#' Get Database Instance
#'
#' @param name Name of the database instance to retrieve.
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @family Database API
#'
#' @returns List
#' @export
db_lakebase_get <- function(
  name,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  req <- db_request(
    endpoint = "database/instances/",
    method = "GET",
    version = "2.0",
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


#' Find Database Instance by UID
#'
#' @param uid UID of the database instance to retrieve.
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @family Database API
#'
#' @returns List
#' @export
db_lakebase_get_by_uid <- function(
  uid,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  req <- db_request(
    endpoint = "database/instances:findByUid",
    method = "GET",
    version = "2.0",
    host = host,
    token = token
  ) |>
    httr2::req_url_query(
      uid = uid
    )

  if (perform_request) {
    db_perform_request(req)
  } else {
    req
  }
}
