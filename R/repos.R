# https://docs.databricks.com/dev-tools/api/latest/repos.html

#' Get All Repos
#'
#' @details Returns repos that the calling user has Manage permissions on.
#' Results are paginated with each page containing twenty repos.
#'
#' @param path_prefix Filters repos that have paths starting with the given path
#' prefix.
#' @param next_page_token Token used to get the next page of results. If not
#' specified, returns the first page of results as well as a next page token if
#' there are more results.
#' @inheritParams auth_params
#' @inheritParams db_sql_endpoint_create
#'
#' @family Repos API
#'
#' @export
db_repo_get_all <- function(path_prefix, next_page_token = NULL,
                            host = db_host(), token = db_token(),
                            perform_request = TRUE) {
  body <- list(
    path_prefix = path_prefix,
    next_page_token = next_page_token
  )

  req <- db_request(
    endpoint = "repos",
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

#' Create Repo
#'
#' Creates a repo in the workspace and links it to the remote Git repo specified.
#'
#' @param url URL of the Git repository to be linked.
#' @param provider Git provider. This field is case-insensitive. The available
#' Git providers are `gitHub`, `bitbucketCloud`, `gitLab`, `azureDevOpsServices`,
#' `gitHubEnterprise`, `bitbucketServer` and `gitLabEnterpriseEdition.`
#' @param path Desired path for the repo in the workspace. Must be in the format
#' `/Repos/{folder}/{repo-name}`.
#' @inheritParams auth_params
#' @inheritParams db_sql_endpoint_create
#'
#' @family Repos API
#'
#' @export
db_repo_create <- function(url, provider, path,
                           host = db_host(), token = db_token(),
                           perform_request = TRUE) {
  body <- list(
    url = url,
    provider = provider,
    path = path
  )

  req <- db_request(
    endpoint = "repos",
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

#' Get Repo
#'
#' Returns the repo with the given repo ID.
#'
#' @param repo_id The ID for the corresponding repo to access.
#' @inheritParams auth_params
#' @inheritParams db_sql_endpoint_create
#'
#' @family Repos API
#'
#' @export
db_repo_get <- function(repo_id,
                        host = db_host(), token = db_token(),
                        perform_request = TRUE) {
  req <- db_request(
    endpoint = paste0("repos/", repo_id),
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

#' Update Repo
#'
#' Updates the repo to the given branch or tag.
#'
#' @param branch Branch that the local version of the repo is checked out to.
#' @param tag Tag that the local version of the repo is checked out to.
#' @inheritParams auth_params
#' @inheritParams db_repo_get
#' @inheritParams db_sql_endpoint_create
#'
#' @details
#'
#' Specify either `branch` or `tag`, not both.
#'
#' Updating the repo to a tag puts the repo in a detached HEAD state.
#' Before committing new changes, you must update the repo to a branch instead
#' of the detached HEAD.
#'
#' @family Repos API
#'
#' @export
db_repo_update <- function(repo_id, branch = NULL, tag = NULL,
                           host = db_host(), token = db_token(),
                           perform_request = TRUE) {
  body <- list(
    endpoint = paste0("repos/", repo_id),
    branch = branch,
    tag = tag
  )

  req <- db_request(
    endpoint = paste0("repos/", repo_id),
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

#' Delete Repo
#'
#' Deletes the specified repo
#'
#' @inheritParams db_repo_get
#' @inheritParams auth_params
#' @inheritParams db_sql_endpoint_create
#'
#' @family Repos API
#'
#' @export
db_repo_delete <- function(repo_id,
                           host = db_host(), token = db_token(),
                           perform_request = TRUE) {
  req <- db_request(
    endpoint = paste0("repos/", repo_id),
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
