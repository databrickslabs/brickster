#' Create Job
#'
#' @param name Name for the job.
#' @param tasks Task specifications to be executed by this job. Use
#' [job_tasks()].
#' @param job_clusters Named list of job cluster specifications (using
#' [new_cluster()]) that can be shared and reused by tasks of this job.
#' Libraries cannot be declared in a shared job cluster. You must declare
#' dependent libraries in task settings.
#' @param parameters Named list of job level parameters. Values of the list
#' represent default values.
#' @param email_notifications Instance of [email_notifications()].
#' @param timeout_seconds An optional timeout applied to each run of this job.
#' The default behavior is to have no timeout.
#' @param schedule Instance of [cron_schedule()].
#' @param max_concurrent_runs Maximum allowed number of concurrent runs of the
#' job. Set this value if you want to be able to execute multiple runs of the
#' same job concurrently. This setting affects only new runs. This value cannot
#' exceed 1000. Setting this value to 0 causes all new runs to be skipped.
#' The default behavior is to allow only 1 concurrent run.
#' @param access_control_list Instance of [access_control_request()].
#' @param git_source Optional specification for a remote repository containing
#' the notebooks used by this job's notebook tasks. Instance of [git_source()].
#' @param queue If true, enable queueing for the job.
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' [Full Documentation](https://docs.databricks.com/api/workspace/jobs/create)
#'
#' @seealso [job_tasks()], [job_task()], [email_notifications()],
#' [cron_schedule()], [access_control_request()], [access_control_req_user()],
#' [access_control_req_group()], [git_source()]
#' @family Jobs API
#'
#' @export
db_jobs_create <- function(
  name,
  tasks,
  schedule = NULL,
  job_clusters = NULL,
  parameters = list(),
  email_notifications = NULL,
  timeout_seconds = NULL,
  max_concurrent_runs = 1,
  access_control_list = NULL,
  git_source = NULL,
  queue = TRUE,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  # parameters converted to nested structure to conform to api
  parameters <- purrr::imap(
    parameters,
    ~ {
      list(name = .y, default = .x)
    }
  )
  parameters <- stats::setNames(parameters, NULL)

  # jobs clusters is transformed to meet API structure required
  job_clusters <- purrr::imap(
    job_clusters,
    ~ {
      stopifnot(is.new_cluster(.x))
      list(
        "job_cluster_key" = .y,
        "new_cluster" = .x
      )
    }
  )
  job_clusters <- unname(job_clusters)

  body <- list(
    name = name,
    tasks = tasks,
    job_clusters = job_clusters,
    email_notifications = email_notifications,
    timeout_seconds = timeout_seconds,
    schedule = schedule,
    max_concurrent_runs = max_concurrent_runs,
    access_control_list = access_control_list,
    git_source = git_source,
    queue = list(enabled = queue),
    parameters = parameters
  )

  body <- purrr::discard(body, is.null)

  req <- db_request(
    endpoint = "jobs/create",
    method = "POST",
    version = "2.2",
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

#' List Jobs
#'
#' @param limit Number of jobs to return. This value must be greater than 0 and
#' less or equal to 25. The default value is 25. If a request specifies a limit
#' of 0, the service instead uses the maximum limit.
#' @param offset The offset of the first job to return, relative to the most
#' recently created job.
#' @param expand_tasks Whether to include task and cluster details in the
#' response.
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @family Jobs API
#'
#' @export
db_jobs_list <- function(
  limit = 25,
  offset = 0,
  expand_tasks = FALSE,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  body <- list(
    limit = as.numeric(limit),
    offset = as.numeric(offset),
    expand_tasks = expand_tasks
  )

  req <- db_request(
    endpoint = "jobs/list",
    method = "GET",
    version = "2.2",
    body = body,
    host = host,
    token = token
  )

  if (perform_request) {
    res <- db_perform_request(req)
    res$jobs
  } else {
    req
  }
}

#' Delete a Job
#'
#' @param job_id The canonical identifier of the job.
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @family Jobs API
#'
#' @export
db_jobs_delete <- function(
  job_id,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  body <- list(
    job_id = as.character(job_id)
  )

  req <- db_request(
    endpoint = "jobs/delete",
    method = "POST",
    version = "2.2",
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

#' Get Job Details
#'
#' @inheritParams auth_params
#' @inheritParams db_jobs_delete
#' @inheritParams db_sql_warehouse_create
#'
#' @family Jobs API
#'
#' @export
db_jobs_get <- function(
  job_id,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  body <- list(
    job_id = as.character(job_id)
  )

  req <- db_request(
    endpoint = "jobs/get",
    method = "GET",
    version = "2.2",
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

#' Overwrite All Settings For A Job
#'
#' @inheritParams auth_params
#' @inheritParams db_jobs_delete
#' @inheritParams db_jobs_create
#' @inheritParams db_sql_warehouse_create
#' @family Jobs API
#'
#' @export
db_jobs_reset <- function(
  job_id,
  name,
  tasks,
  schedule = NULL,
  job_clusters = NULL,
  parameters = list(),
  email_notifications = NULL,
  timeout_seconds = NULL,
  max_concurrent_runs = 1,
  access_control_list = NULL,
  git_source = NULL,
  queue = NULL,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  parameters <- purrr::imap(
    parameters,
    ~ {
      list(name = .y, default = .x)
    }
  )
  parameters <- stats::setNames(parameters, NULL)

  if (!is.null(queue)) {
    queue <- list(enabled = queue)
  }

  job_clusters <- prepare_jobs_clusters(job_clusters)
  body <- list(
    name = name,
    tasks = tasks,
    job_clusters = job_clusters,
    email_notifications = email_notifications,
    timeout_seconds = timeout_seconds,
    schedule = schedule,
    max_concurrent_runs = max_concurrent_runs,
    access_control_list = access_control_list,
    git_source = git_source,
    queue = queue,
    parameters = parameters
  )

  body <- purrr::discard(body, is.null)
  body <- list(job_id = job_id, new_settings = body)

  req <- db_request(
    endpoint = "jobs/reset",
    method = "POST",
    version = "2.2",
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

#' Partially Update A Job
#'
#' @param fields_to_remove Remove top-level fields in the job settings. Removing
#' nested fields is not supported. This field is optional. Must be a `list()`.
#' @inheritParams auth_params
#' @inheritParams db_jobs_reset
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' Parameters which are shared with [db_jobs_create()] are optional, only
#' specify those that are changing. Job-level parameters can be updated using
#' the same structure as `db_jobs_create()`.
#'
#' @family Jobs API
#'
#' @export
db_jobs_update <- function(
  job_id,
  fields_to_remove = list(),
  name = NULL,
  schedule = NULL,
  tasks = NULL,
  job_clusters = NULL,
  parameters = NULL,
  email_notifications = NULL,
  timeout_seconds = NULL,
  max_concurrent_runs = NULL,
  access_control_list = NULL,
  git_source = NULL,
  queue = NULL,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  # jobs clusters is transformed to meet API structure required
  job_clusters <- prepare_jobs_clusters(job_clusters)
  if (!is.null(parameters)) {
    parameters <- purrr::imap(
      parameters,
      ~ {
        list(name = .y, default = .x)
      }
    )
    parameters <- stats::setNames(parameters, NULL)
  }

  if (!is.null(queue)) {
    queue <- list(enabled = queue)
  }

  body <- list(
    name = name,
    tasks = tasks,
    job_clusters = job_clusters,
    parameters = parameters,
    email_notifications = email_notifications,
    timeout_seconds = timeout_seconds,
    schedule = schedule,
    max_concurrent_runs = max_concurrent_runs,
    access_control_list = access_control_list,
    git_source = git_source,
    queue = queue
  )

  body <- purrr::discard(body, is.null)
  body <- list(
    job_id = job_id,
    new_settings = body,
    fields_to_remove = fields_to_remove
  )

  req <- db_request(
    endpoint = "jobs/update",
    method = "POST",
    version = "2.2",
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

#' Repair A Job Run
#'
#' @param run_id Job run ID of the run to repair. The run must not be in progress.
#' @param rerun_tasks Character vector. Task keys of the task runs to repair.
#' @param job_parameters Named list of job level parameters used in the run.
#' @param latest_repair_id The ID of the latest repair. This parameter is not required
#' when repairing a run for the first time, but must be provided on subsequent requests
#' to repair the same run.
#' @param performance_target The performance mode on a serverless job (either
#' `'PERFORMANCE_OPTIMIZED'` or `'STANDARD'`). The performance target determines
#' the level of compute performance or cost-efficiency for the run. This field
#' overrides the performance target defined on the job level.
#' @param pipeline_full_refresh Boolean. Controls whether the pipeline should perform
#' a full refresh.
#' @param rerun_all_failed_tasks Boolean. If `TRUE`, repair all failed tasks.
#' Only one of `rerun_tasks` or `rerun_all_failed_tasks` can be used.
#' @param rerun_dependent_tasks Boolean. If `TRUE`, repair all tasks that depend
#' on the tasks in `rerun_tasks`, even if they were previously successful. Can be
#' also used in combination with `rerun_all_failed_tasks.`
#' @inheritParams auth_params
#' @inheritParams db_jobs_reset
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' Parameters which are shared with [db_jobs_create()] are optional, only
#' specify those that are changing.
#'
#' @family Jobs API
#'
#' @export
db_jobs_repair_run <- function(
  run_id,
  rerun_tasks = NULL,
  job_parameters = list(),
  latest_repair_id = NULL,
  performance_target = NULL,
  pipeline_full_refresh = NULL,
  rerun_all_failed_tasks = NULL,
  rerun_dependent_tasks = NULL,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  # only one of rerun_tasks or rerun_all_failed_tasks can be specified
  if (!is.null(rerun_tasks) && !is.null(rerun_all_failed_tasks)) {
    cli::cli_abort(
      "Only one of {.arg rerun_tasks} or {.arg rerun_all_failed_tasks} can be specified."
    )
  }

  if (!is.null(performance_target)) {
    performance_target <- match.arg(
      performance_target,
      choices = c("PERFORMANCE_OPTIMIZED", "STANDARD")
    )
  }

  job_parameters <- purrr::imap(
    job_parameters,
    ~ {
      list(name = .y, default = .x)
    }
  )
  job_parameters <- stats::setNames(job_parameters, NULL)

  body <- list(
    run_id = as.character(run_id),
    rerun_tasks = rerun_tasks,
    job_parameters = job_parameters,
    latest_repair_id = latest_repair_id,
    performance_target = performance_target,
    rerun_all_failed_tasks = rerun_all_failed_tasks,
    rerun_dependent_tasks = rerun_dependent_tasks
  )

  body <- purrr::discard(body, is.null)

  if (!is.null(pipeline_full_refresh)) {
    body$pipeline_params <- list(full_refresh = pipeline_full_refresh)
  }

  req <- db_request(
    endpoint = "jobs/runs/repair",
    method = "POST",
    version = "2.2",
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


#' Trigger A New Job Run
#'
#' @param parameters Named list of job level parameters.
#' @inheritParams auth_params
#' @inheritParams db_jobs_get
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' * `*_params` parameters cannot exceed 10,000 bytes when serialized to JSON.
#' * `jar_params` and `notebook_params` are mutually exclusive.
#'
#' @family Jobs API
#'
#' @export
db_jobs_run_now <- function(
  job_id,
  parameters = list(),
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  body <- list(
    job_id = job_id,
    job_parameters = parameters
  )

  req <- db_request(
    endpoint = "jobs/run-now",
    method = "POST",
    version = "2.2",
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

#' Create And Trigger A One-Time Run
#'
#' @param run_name Name for the run.
#' @param idempotency_token An optional token that can be used to guarantee the
#' idempotency of job run requests. If an active run with the provided token
#' already exists, the request does not create a new run, but returns the ID of
#' the existing run instead. If you specify the idempotency token, upon failure
#' you can retry until the request succeeds. Databricks guarantees that exactly
#' one run is launched with that idempotency token. This token must have at most
#' 64 characters.
#' @inheritParams auth_params
#' @inheritParams db_jobs_create
#' @inheritParams db_sql_warehouse_create
#'
#' @family Jobs API
#'
#' @export
db_jobs_runs_submit <- function(
  tasks,
  run_name,
  timeout_seconds = NULL,
  idempotency_token = NULL,
  access_control_list = NULL,
  git_source = NULL,
  job_clusters = NULL,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  # jobs clusters is transformed to meet API structure required
  job_clusters <- prepare_jobs_clusters(job_clusters)

  body <- list(
    run_name = run_name,
    tasks = tasks,
    job_clusters = job_clusters,
    idempotency_token = idempotency_token,
    timeout_seconds = timeout_seconds,
    access_control_list = access_control_list,
    git_source = git_source
  )

  body <- purrr::discard(body, is.null)

  req <- db_request(
    endpoint = "jobs/runs/submit",
    method = "POST",
    version = "2.2",
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

#' List Job Runs
#'
#' List runs in descending order by start time.
#'
#' @param active_only Boolean (Default: `FALSE`). If `TRUE` only active runs are
#' included in the results; otherwise, lists both active and completed runs.
#' An active run is a run in the `PENDING`, `RUNNING`, or `TERMINATING`. This
#' field cannot be true when `completed_only` is `TRUE`.
#' @param completed_only Boolean (Default: `FALSE`). If `TRUE`, only completed
#' runs are included in the results; otherwise, lists both active and completed
#' runs. This field cannot be true when `active_only` is `TRUE`.
#' @param run_type The type of runs to return. One of `JOB_RUN`, `WORKFLOW_RUN`,
#' `SUBMIT_RUN`.
#' @inheritParams auth_params
#' @inheritParams db_jobs_get
#' @inheritParams db_jobs_list
#' @inheritParams db_sql_warehouse_create
#'
#' @family Jobs API
#'
#' @export
db_jobs_runs_list <- function(
  job_id,
  active_only = FALSE,
  completed_only = FALSE,
  offset = 0,
  limit = 25,
  run_type = c("JOB_RUN", "WORKFLOW_RUN", "SUBMIT_RUN"),
  expand_tasks = FALSE,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  run_type <- match.arg(run_type, several.ok = FALSE)

  if (active_only && completed_only) {
    cli::cli_abort(
      "{.arg active_only} and {.arg completed_only} cannot both be {.val TRUE}."
    )
  }

  body <- list(
    job_id = as.character(job_id),
    active_only = active_only,
    completed_only = completed_only,
    offset = as.numeric(offset),
    limit = as.numeric(limit),
    run_type = run_type,
    expand_tasks = expand_tasks
  )

  req <- db_request(
    endpoint = "jobs/runs/list",
    method = "GET",
    version = "2.2",
    body = body,
    host = host,
    token = token
  )

  if (perform_request) {
    res <- db_perform_request(req)
    res$runs
  } else {
    req
  }
}

#' Get Job Run Details
#'
#' Retrieve the metadata of a run.
#'
#' @param run_id The canonical identifier of the run.
#' @inheritParams auth_params
#' @inheritParams db_sql_warehouse_create
#'
#' @family Jobs API
#'
#' @export
db_jobs_runs_get <- function(
  run_id,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  body <- list(
    run_id = as.character(run_id)
  )

  req <- db_request(
    endpoint = "jobs/runs/get",
    method = "GET",
    version = "2.2",
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

#' Export Job Run Output
#'
#' Export and retrieve the job run task.
#'
#' @param views_to_export Which views to export. One of `CODE`, `DASHBOARDS`,
#' `ALL`. Defaults to `CODE`.
#' @inheritParams auth_params
#' @inheritParams db_jobs_runs_get
#' @inheritParams db_sql_warehouse_create
#'
#' @family Jobs API
#'
#' @export
db_jobs_runs_export <- function(
  run_id,
  views_to_export = c("CODE", "DASHBOARDS", "ALL"),
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  # TODO: could add the ability to directly parse the outputs to files?
  views_to_export <- match.arg(views_to_export, several.ok = FALSE)

  body <- list(
    run_id = as.character(run_id),
    views_to_export = views_to_export
  )

  req <- db_request(
    endpoint = "jobs/runs/export",
    method = "GET",
    version = "2.2",
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

#' Cancel Job Run
#'
#' Cancels a run.
#'
#' @inheritParams auth_params
#' @inheritParams db_jobs_runs_get
#' @inheritParams db_sql_warehouse_create
#'
#' @details
#' The run is canceled asynchronously, so when this request completes, the run
#' may still be running. The run are terminated shortly. If the run is already
#' in a terminal `life_cycle_state`, this method is a no-op.
#'
#' @family Jobs API
#'
#' @export
db_jobs_runs_cancel <- function(
  run_id,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  body <- list(
    run_id = as.character(run_id)
  )

  req <- db_request(
    endpoint = "jobs/runs/cancel",
    method = "POST",
    version = "2.2",
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

#' Get Job Run Output
#'
#' @inheritParams auth_params
#' @inheritParams db_jobs_runs_get
#' @inheritParams db_sql_warehouse_create
#'
#' @family Jobs API
#'
#' @export
db_jobs_runs_get_output <- function(
  run_id,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  body <- list(
    run_id = as.character(run_id)
  )

  req <- db_request(
    endpoint = "jobs/runs/get-output",
    method = "GET",
    version = "2.2",
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

#' Delete Job Run
#'
#' @inheritParams auth_params
#' @inheritParams db_jobs_runs_get
#' @inheritParams db_sql_warehouse_create
#'
#' @family Jobs API
#'
#' @export
db_jobs_runs_delete <- function(
  run_id,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
) {
  body <- list(
    run_id = as.character(run_id)
  )

  req <- db_request(
    endpoint = "jobs/runs/delete",
    method = "POST",
    version = "2.2",
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


prepare_jobs_clusters <- function(x) {
  # jobs clusters is transformed to meet API structure required
  job_clusters <- purrr::imap(
    x,
    ~ {
      stopifnot(is.new_cluster(.x))
      list(
        "job_cluster_key" = .y,
        "new_cluster" = .x
      )
    }
  )
  job_clusters <- unname(job_clusters)
}
