# Create And Trigger A One-Time Run

Create And Trigger A One-Time Run

## Usage

``` r
db_jobs_runs_submit(
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
)
```

## Arguments

- tasks:

  Task specifications to be executed by this job. Use
  [`job_tasks()`](https://databrickslabs.github.io/brickster/reference/job_tasks.md).

- run_name:

  Name for the run.

- timeout_seconds:

  An optional timeout applied to each run of this job. The default
  behavior is to have no timeout.

- idempotency_token:

  An optional token that can be used to guarantee the idempotency of job
  run requests. If an active run with the provided token already exists,
  the request does not create a new run, but returns the ID of the
  existing run instead. If you specify the idempotency token, upon
  failure you can retry until the request succeeds. Databricks
  guarantees that exactly one run is launched with that idempotency
  token. This token must have at most 64 characters.

- access_control_list:

  Instance of
  [`access_control_request()`](https://databrickslabs.github.io/brickster/reference/access_control_request.md).

- git_source:

  Optional specification for a remote repository containing the
  notebooks used by this job's notebook tasks. Instance of
  [`git_source()`](https://databrickslabs.github.io/brickster/reference/git_source.md).

- job_clusters:

  Named list of job cluster specifications (using
  [`new_cluster()`](https://databrickslabs.github.io/brickster/reference/new_cluster.md))
  that can be shared and reused by tasks of this job. Libraries cannot
  be declared in a shared job cluster. You must declare dependent
  libraries in task settings.

- host:

  Databricks workspace URL, defaults to calling
  [`db_host()`](https://databrickslabs.github.io/brickster/reference/db_host.md).

- token:

  Databricks workspace token, defaults to calling
  [`db_token()`](https://databrickslabs.github.io/brickster/reference/db_token.md).

- perform_request:

  If `TRUE` (default) the request is performed, if `FALSE` the httr2
  request is returned *without* being performed.

## See also

Other Jobs API:
[`db_jobs_create()`](https://databrickslabs.github.io/brickster/reference/db_jobs_create.md),
[`db_jobs_delete()`](https://databrickslabs.github.io/brickster/reference/db_jobs_delete.md),
[`db_jobs_get()`](https://databrickslabs.github.io/brickster/reference/db_jobs_get.md),
[`db_jobs_list()`](https://databrickslabs.github.io/brickster/reference/db_jobs_list.md),
[`db_jobs_repair_run()`](https://databrickslabs.github.io/brickster/reference/db_jobs_repair_run.md),
[`db_jobs_reset()`](https://databrickslabs.github.io/brickster/reference/db_jobs_reset.md),
[`db_jobs_run_now()`](https://databrickslabs.github.io/brickster/reference/db_jobs_run_now.md),
[`db_jobs_runs_cancel()`](https://databrickslabs.github.io/brickster/reference/db_jobs_runs_cancel.md),
[`db_jobs_runs_delete()`](https://databrickslabs.github.io/brickster/reference/db_jobs_runs_delete.md),
[`db_jobs_runs_export()`](https://databrickslabs.github.io/brickster/reference/db_jobs_runs_export.md),
[`db_jobs_runs_get()`](https://databrickslabs.github.io/brickster/reference/db_jobs_runs_get.md),
[`db_jobs_runs_get_output()`](https://databrickslabs.github.io/brickster/reference/db_jobs_runs_get_output.md),
[`db_jobs_runs_list()`](https://databrickslabs.github.io/brickster/reference/db_jobs_runs_list.md),
[`db_jobs_update()`](https://databrickslabs.github.io/brickster/reference/db_jobs_update.md)
