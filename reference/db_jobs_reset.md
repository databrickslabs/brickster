# Overwrite All Settings For A Job

Overwrite All Settings For A Job

## Usage

``` r
db_jobs_reset(
  job_id,
  name,
  schedule,
  tasks,
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
)
```

## Arguments

- job_id:

  The canonical identifier of the job.

- name:

  Name for the job.

- schedule:

  Instance of
  [`cron_schedule()`](https://databrickslabs.github.io/brickster/reference/cron_schedule.md).

- tasks:

  Task specifications to be executed by this job. Use
  [`job_tasks()`](https://databrickslabs.github.io/brickster/reference/job_tasks.md).

- job_clusters:

  Named list of job cluster specifications (using
  [`new_cluster()`](https://databrickslabs.github.io/brickster/reference/new_cluster.md))
  that can be shared and reused by tasks of this job. Libraries cannot
  be declared in a shared job cluster. You must declare dependent
  libraries in task settings.

- parameters:

  Named list of job level parameters. Values of the list represent
  default values.

- email_notifications:

  Instance of
  [`email_notifications()`](https://databrickslabs.github.io/brickster/reference/email_notifications.md).

- timeout_seconds:

  An optional timeout applied to each run of this job. The default
  behavior is to have no timeout.

- max_concurrent_runs:

  Maximum allowed number of concurrent runs of the job. Set this value
  if you want to be able to execute multiple runs of the same job
  concurrently. This setting affects only new runs. This value cannot
  exceed 1000. Setting this value to 0 causes all new runs to be
  skipped. The default behavior is to allow only 1 concurrent run.

- access_control_list:

  Instance of
  [`access_control_request()`](https://databrickslabs.github.io/brickster/reference/access_control_request.md).

- git_source:

  Optional specification for a remote repository containing the
  notebooks used by this job's notebook tasks. Instance of
  [`git_source()`](https://databrickslabs.github.io/brickster/reference/git_source.md).

- queue:

  If true, enable queueing for the job.

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
[`db_jobs_run_now()`](https://databrickslabs.github.io/brickster/reference/db_jobs_run_now.md),
[`db_jobs_runs_cancel()`](https://databrickslabs.github.io/brickster/reference/db_jobs_runs_cancel.md),
[`db_jobs_runs_delete()`](https://databrickslabs.github.io/brickster/reference/db_jobs_runs_delete.md),
[`db_jobs_runs_export()`](https://databrickslabs.github.io/brickster/reference/db_jobs_runs_export.md),
[`db_jobs_runs_get()`](https://databrickslabs.github.io/brickster/reference/db_jobs_runs_get.md),
[`db_jobs_runs_get_output()`](https://databrickslabs.github.io/brickster/reference/db_jobs_runs_get_output.md),
[`db_jobs_runs_list()`](https://databrickslabs.github.io/brickster/reference/db_jobs_runs_list.md),
[`db_jobs_runs_submit()`](https://databrickslabs.github.io/brickster/reference/db_jobs_runs_submit.md),
[`db_jobs_update()`](https://databrickslabs.github.io/brickster/reference/db_jobs_update.md)
