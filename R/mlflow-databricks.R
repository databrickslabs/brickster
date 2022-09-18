# https://docs.databricks.com/dev-tools/api/latest/mlflow.html

#' Get Registered Model Details
#'
#' @param name Name of the model.
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @family Model Registry API
#'
#' @export
db_mlflow_registered_model_details <- function(name,
                                               host = db_host(), token = db_token(),
                                               perform_request = TRUE) {
  body <- list(
    name = name
  )

  req <- db_request(
    endpoint = "mlflow/databricks/registered-models/get",
    method = "GET",
    version = "2.0",
    body = body,
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)[[1]]
  } else {
    req
  }

}

#' Transition a Model Version's Stage
#'
#' @param version Version of the model.
#' @param stage Target stage of the transition. Valid values are: `None`,
#' `Staging`, `Production`, `Archived`.
#' @param archive_existing_versions Boolean (Default: `TRUE`). Specifies whether
#' to archive all current model versions in the target stage.
#' @param comment User-provided comment on the action.
#' @inheritParams auth_params
#' @inheritParams db_mlflow_registered_model_details
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' This is a Databricks version of the MLflow endpoint that also accepts a
#' comment associated with the transition to be recorded.
#'
#' @family Model Registry API
#'
#' @export
db_mlflow_model_transition_stage <- function(name, version,
                                             stage = c("None", "Staging", "Production", "Archived"),
                                             archive_existing_versions = TRUE,
                                             comment = NULL,
                                             host = db_host(), token = db_token(),
                                             perform_request = TRUE) {
  stage <- match.arg(stage, several.ok = FALSE)

  body <- list(
    name = name,
    version = as.character(version),
    stage = stage,
    archive_existing_versions = archive_existing_versions,
    comment = comment
  )

  req <- db_request(
    endpoint = "mlflow/databricks/model-versions/transition-stage",
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

#' Make a Model Version Stage Transition Request
#'
#' @inheritParams auth_params
#' @inheritParams db_mlflow_model_transition_stage
#' @inheritParams db_sql_warehouse_create
#'
#' @family Model Registry API
#'
#' @export
db_mlflow_model_transition_req <- function(name, version,
                                           stage = c("None", "Staging", "Production", "Archived"),
                                           comment = NULL,
                                           host = db_host(), token = db_token(),
                                           perform_request = TRUE) {
  stage <- match.arg(stage, several.ok = FALSE)

  body <- list(
    name = name,
    version = as.character(version),
    stage = stage,
    comment = comment
  )

  req <- db_request(
    endpoint = "mlflow/transition-requests/create",
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

#' Get All Open Stage Transition Requests for the Model Version
#'
#' @inheritParams auth_params
#' @inheritParams db_mlflow_model_transition_stage
#' @inheritParams db_sql_warehouse_create
#'
#' @family Model Registry API
#'
#' @export
db_mlflow_model_open_transition_reqs <- function(name, version,
                                                 host = db_host(), token = db_token(),
                                                 perform_request = TRUE) {
  body <- list(
    name = name,
    version = as.character(version)
  )

  req <- db_request(
    endpoint = "mlflow/transition-requests/list",
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

#' Approve Model Version Stage Transition Request
#'
#' @inheritParams auth_params
#' @inheritParams db_mlflow_model_transition_stage
#' @inheritParams db_sql_warehouse_create
#'
#' @family Model Registry API
#'
#' @export
db_mlflow_model_approve_transition_req <- function(name, version,
                                                   stage = c("None", "Staging", "Production", "Archived"),
                                                   archive_existing_versions = TRUE,
                                                   comment = NULL,
                                                   host = db_host(), token = db_token(),
                                                   perform_request = TRUE) {
  stage <- match.arg(stage, several.ok = FALSE)

  body <- list(
    name = name,
    version = as.character(version),
    stage = stage,
    archive_existing_versions = archive_existing_versions,
    comment = comment
  )

  req <- db_request(
    endpoint = "mlflow/transition-requests/approve",
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

#' Reject Model Version Stage Transition Request
#'
#' @inheritParams auth_params
#' @inheritParams db_mlflow_model_transition_stage
#' @inheritParams db_sql_warehouse_create
#'
#' @family Model Registry API
#'
#' @export
db_mlflow_model_reject_transition_req <- function(name, version,
                                                  stage = c("None", "Staging", "Production", "Archived"),
                                                  comment = NULL,
                                                  host = db_host(), token = db_token(),
                                                  perform_request = TRUE) {
  stage <- match.arg(stage, several.ok = FALSE)

  body <- list(
    name = name,
    version = as.character(version),
    stage = stage,
    comment = comment
  )

  req <- db_request(
    endpoint = "mlflow/transition-requests/reject",
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

#' Delete a Model Version Stage Transition Request
#'
#' @param creator Username of the user who created this request. Of the
#' transition requests matching the specified details, only the one transition
#' created by this user will be deleted.
#' @inheritParams auth_params
#' @inheritParams db_mlflow_model_transition_stage
#' @inheritParams db_sql_warehouse_create
#'
#' @family Model Registry API
#'
#' @export
db_mlflow_model_delete_transition_req <- function(name, version,
                                                  stage = c("None", "Staging", "Production", "Archived"),
                                                  creator, comment = NULL,
                                                  host = db_host(), token = db_token(),
                                                  perform_request = TRUE) {
  stage <- match.arg(stage, several.ok = FALSE)

  body <- list(
    name = name,
    version = as.character(version),
    stage = stage,
    creator = creator,
    comment = comment
  )

  req <- db_request(
    endpoint = "mlflow/transition-requests/delete",
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

#' Make a Comment on a Model Version
#'
#' @inheritParams auth_params
#' @inheritParams db_mlflow_model_transition_stage
#' @inheritParams db_sql_warehouse_create
#'
#' @family Model Registry API
#'
#' @export
db_mlflow_model_version_comment <- function(name, version, comment,
                                            host = db_host(), token = db_token(),
                                            perform_request = TRUE) {
  body <- list(
    name = name,
    version = as.character(version),
    comment = comment
  )

  req <- db_request(
    endpoint = "mlflow/comments/create",
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

#' Edit a Comment on a Model Version
#'
#' @param id Unique identifier of an activity.
#' @inheritParams auth_params
#' @inheritParams db_mlflow_model_transition_stage
#' @inheritParams db_sql_warehouse_create
#'
#' @family Model Registry API
#'
#' @export
db_mlflow_model_version_comment_edit <- function(id, comment,
                                                 host = db_host(), token = db_token(),
                                                 perform_request = TRUE) {
  body <- list(
    id = id,
    comment = comment
  )

  req <- db_request(
    endpoint = "mlflow/comments/update",
    method = "PATCH",
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

#' Delete a Comment on a Model Version
#'
#' @inheritParams auth_params
#' @inheritParams db_mlflow_model_version_comment_edit
#' @inheritParams db_sql_warehouse_create
#'
#' @family Model Registry API
#'
#' @export
db_mlflow_model_version_comment_delete <- function(id,
                                                   host = db_host(), token = db_token(),
                                                   perform_request = TRUE) {
  body <- list(
    id = id
  )

  req <- db_request(
    endpoint = "mlflow/comments/delete",
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

# undocumented endpoints
db_mlflow_registered_models_list <- function(max_results = 100,
                                             page_token = NULL,
                                             host = db_host(), token = db_token(),
                                             perform_request = TRUE) {

  body <- list(
    max_results = max_results,
    page_token = page_token
  )

  req <- db_request(
    endpoint = "mlflow/registered-models/list",
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

db_mlflow_registered_models_search <- function(filter = NULL,
                                               max_results = 100,
                                               order_by = list(),
                                               page_token = NULL,
                                               host = db_host(), token = db_token(),
                                               perform_request = TRUE) {

  body <- list(
    filter = filter,
    max_results = max_results,
    page_token = page_token,
    order_by = order_by
  )

  req <- db_request(
    endpoint = "mlflow/registered-models/search",
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

db_mlflow_registered_models_search_versions <- function(name,
                                                        max_results = 10000,
                                                        order_by = list(),
                                                        page_token = NULL,
                                                        host = db_host(), token = db_token(),
                                                        perform_request = TRUE) {

  body <- list(
    filter = paste0("name='", name, "'"),
    max_results = max_results,
    page_token = page_token,
    order_by = order_by
  )

  req <- db_request(
    endpoint = "mlflow/model-versions/search",
    method = "GET",
    version = "2.0",
    body = body,
    host = host,
    token = token
  )

  if (perform_request) {
    db_perform_request(req)$model_versions
  } else {
    req
  }
}
