# Email Notifications

Email Notifications

## Usage

``` r
email_notifications(
  on_start = NULL,
  on_success = NULL,
  on_failure = NULL,
  no_alert_for_skipped_runs = TRUE
)
```

## Arguments

- on_start:

  List of email addresses to be notified when a run begins. If not
  specified on job creation, reset, or update, the list is empty, and
  notifications are not sent.

- on_success:

  List of email addresses to be notified when a run successfully
  completes. A run is considered to have completed successfully if it
  ends with a `TERMINATED` `life_cycle_state` and a `SUCCESSFUL`
  `result_state.` If not specified on job creation, reset, or update,
  the list is empty, and notifications are not sent.

- on_failure:

  List of email addresses to be notified when a run unsuccessfully
  completes. A run is considered to have completed unsuccessfully if it
  ends with an `INTERNAL_ERROR` `life_cycle_state` or a `SKIPPED`,
  `FAILED`, or `TIMED_OUT` `result_state.` If this is not specified on
  job creation, reset, or update the list is empty, and notifications
  are not sent.

- no_alert_for_skipped_runs:

  If `TRUE` (default), do not send email to recipients specified in
  `on_failure` if the run is skipped.

## See also

[`job_task()`](https://databrickslabs.github.io/brickster/reference/job_task.md)

Other Task Objects:
[`condition_task()`](https://databrickslabs.github.io/brickster/reference/condition_task.md),
[`for_each_task()`](https://databrickslabs.github.io/brickster/reference/for_each_task.md),
[`libraries()`](https://databrickslabs.github.io/brickster/reference/libraries.md),
[`new_cluster()`](https://databrickslabs.github.io/brickster/reference/new_cluster.md),
[`notebook_task()`](https://databrickslabs.github.io/brickster/reference/notebook_task.md),
[`pipeline_task()`](https://databrickslabs.github.io/brickster/reference/pipeline_task.md),
[`python_wheel_task()`](https://databrickslabs.github.io/brickster/reference/python_wheel_task.md),
[`run_job_task()`](https://databrickslabs.github.io/brickster/reference/run_job_task.md),
[`spark_jar_task()`](https://databrickslabs.github.io/brickster/reference/spark_jar_task.md),
[`spark_python_task()`](https://databrickslabs.github.io/brickster/reference/spark_python_task.md),
[`spark_submit_task()`](https://databrickslabs.github.io/brickster/reference/spark_submit_task.md),
[`sql_file_task()`](https://databrickslabs.github.io/brickster/reference/sql_file_task.md),
[`sql_query_task()`](https://databrickslabs.github.io/brickster/reference/sql_query_task.md)
