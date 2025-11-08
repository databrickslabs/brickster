# Repair A Job Run

Repair A Job Run

## Usage

``` r
db_jobs_repair_run(
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
)
```

## Arguments

- run_id:

  Job run ID of the run to repair. The run must not be in progress.

- rerun_tasks:

  Character vector. Task keys of the task runs to repair.

- job_parameters:

  Named list of job level parameters used in the run.

- latest_repair_id:

  The ID of the latest repair. This parameter is not required when
  repairing a run for the first time, but must be provided on subsequent
  requests to repair the same run.

- performance_target:

  The performance mode on a serverless job (either
  `'PERFORMANCE_OPTIMIZED'` or `'STANDARD'`). The performance target
  determines the level of compute performance or cost-efficiency for the
  run. This field overrides the performance target defined on the job
  level.

- pipeline_full_refresh:

  Boolean. Controls whether the pipeline should perform a full refresh.

- rerun_all_failed_tasks:

  Boolean. If `TRUE`, repair all failed tasks. Only one of `rerun_tasks`
  or `rerun_all_failed_tasks` can be used.

- rerun_dependent_tasks:

  Boolean. If `TRUE`, repair all tasks that depend on the tasks in
  `rerun_tasks`, even if they were previously successful. Can be also
  used in combination with `rerun_all_failed_tasks.`

- host:

  Databricks workspace URL, defaults to calling
  [`db_host()`](https://databrickslabs.github.io/brickster/reference/db_host.md).

- token:

  Databricks workspace token, defaults to calling
  [`db_token()`](https://databrickslabs.github.io/brickster/reference/db_token.md).

- perform_request:

  If `TRUE` (default) the request is performed, if `FALSE` the httr2
  request is returned *without* being performed.

## Details

Parameters which are shared with
[`db_jobs_create()`](https://databrickslabs.github.io/brickster/reference/db_jobs_create.md)
are optional, only specify those that are changing.

## See also

Other Jobs API:
[`db_jobs_create()`](https://databrickslabs.github.io/brickster/reference/db_jobs_create.md),
[`db_jobs_delete()`](https://databrickslabs.github.io/brickster/reference/db_jobs_delete.md),
[`db_jobs_get()`](https://databrickslabs.github.io/brickster/reference/db_jobs_get.md),
[`db_jobs_list()`](https://databrickslabs.github.io/brickster/reference/db_jobs_list.md),
[`db_jobs_reset()`](https://databrickslabs.github.io/brickster/reference/db_jobs_reset.md),
[`db_jobs_run_now()`](https://databrickslabs.github.io/brickster/reference/db_jobs_run_now.md),
[`db_jobs_runs_cancel()`](https://databrickslabs.github.io/brickster/reference/db_jobs_runs_cancel.md),
[`db_jobs_runs_delete()`](https://databrickslabs.github.io/brickster/reference/db_jobs_runs_delete.md),
[`db_jobs_runs_export()`](https://databrickslabs.github.io/brickster/reference/db_jobs_runs_export.md),
[`db_jobs_runs_get()`](https://databrickslabs.github.io/brickster/reference/db_jobs_runs_get.md),
[`db_jobs_runs_get_output()`](https://databrickslabs.github.io/brickster/reference/db_jobs_runs_get_output.md),
[`db_jobs_runs_list()`](https://databrickslabs.github.io/brickster/reference/db_jobs_runs_list.md),
[`db_jobs_runs_submit()`](https://databrickslabs.github.io/brickster/reference/db_jobs_runs_submit.md),
[`db_jobs_update()`](https://databrickslabs.github.io/brickster/reference/db_jobs_update.md)
