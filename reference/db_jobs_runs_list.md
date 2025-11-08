# List Job Runs

List runs in descending order by start time.

## Usage

``` r
db_jobs_runs_list(
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
)
```

## Arguments

- job_id:

  The canonical identifier of the job.

- active_only:

  Boolean (Default: `FALSE`). If `TRUE` only active runs are included in
  the results; otherwise, lists both active and completed runs. An
  active run is a run in the `PENDING`, `RUNNING`, or `TERMINATING`.
  This field cannot be true when `completed_only` is `TRUE`.

- completed_only:

  Boolean (Default: `FALSE`). If `TRUE`, only completed runs are
  included in the results; otherwise, lists both active and completed
  runs. This field cannot be true when `active_only` is `TRUE`.

- offset:

  The offset of the first job to return, relative to the most recently
  created job.

- limit:

  Number of jobs to return. This value must be greater than 0 and less
  or equal to 25. The default value is 25. If a request specifies a
  limit of 0, the service instead uses the maximum limit.

- run_type:

  The type of runs to return. One of `JOB_RUN`, `WORKFLOW_RUN`,
  `SUBMIT_RUN`.

- expand_tasks:

  Whether to include task and cluster details in the response.

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
[`db_jobs_runs_submit()`](https://databrickslabs.github.io/brickster/reference/db_jobs_runs_submit.md),
[`db_jobs_update()`](https://databrickslabs.github.io/brickster/reference/db_jobs_update.md)
