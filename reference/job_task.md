# Job Task

Job Task

## Usage

``` r
job_task(
  task_key,
  description = NULL,
  depends_on = c(),
  existing_cluster_id = NULL,
  new_cluster = NULL,
  job_cluster_key = NULL,
  task,
  libraries = NULL,
  email_notifications = NULL,
  timeout_seconds = NULL,
  max_retries = 0,
  min_retry_interval_millis = 0,
  retry_on_timeout = FALSE,
  run_if = c("ALL_SUCCESS", "ALL_DONE", "NONE_FAILED", "AT_LEAST_ONE_SUCCESS",
    "ALL_FAILED", "AT_LEAST_ONE_FAILED")
)
```

## Arguments

- task_key:

  A unique name for the task. This field is used to refer to this task
  from other tasks. This field is required and must be unique within its
  parent job. On
  [`db_jobs_update()`](https://databrickslabs.github.io/brickster/reference/db_jobs_update.md)
  or
  [`db_jobs_reset()`](https://databrickslabs.github.io/brickster/reference/db_jobs_reset.md),
  this field is used to reference the tasks to be updated or reset. The
  maximum length is 100 characters.

- description:

  An optional description for this task. The maximum length is 4096
  bytes.

- depends_on:

  Vector of `task_key`'s specifying the dependency graph of the task.
  All `task_key`'s specified in this field must complete successfully
  before executing this task. This field is required when a job consists
  of more than one task.

- existing_cluster_id:

  ID of an existing cluster that is used for all runs of this task.

- new_cluster:

  Instance of
  [`new_cluster()`](https://databrickslabs.github.io/brickster/reference/new_cluster.md).

- job_cluster_key:

  Task is executed reusing the cluster specified in
  [`db_jobs_create()`](https://databrickslabs.github.io/brickster/reference/db_jobs_create.md)
  with `job_clusters` parameter.

- task:

  One of
  [`notebook_task()`](https://databrickslabs.github.io/brickster/reference/notebook_task.md),
  [`spark_jar_task()`](https://databrickslabs.github.io/brickster/reference/spark_jar_task.md),
  [`spark_python_task()`](https://databrickslabs.github.io/brickster/reference/spark_python_task.md),
  [`spark_submit_task()`](https://databrickslabs.github.io/brickster/reference/spark_submit_task.md),
  [`pipeline_task()`](https://databrickslabs.github.io/brickster/reference/pipeline_task.md),
  [`python_wheel_task()`](https://databrickslabs.github.io/brickster/reference/python_wheel_task.md).

- libraries:

  Instance of
  [`libraries()`](https://databrickslabs.github.io/brickster/reference/libraries.md).

- email_notifications:

  Instance of
  [email_notifications](https://databrickslabs.github.io/brickster/reference/email_notifications.md).

- timeout_seconds:

  An optional timeout applied to each run of this job task. The default
  behavior is to have no timeout.

- max_retries:

  An optional maximum number of times to retry an unsuccessful run. A
  run is considered to be unsuccessful if it completes with the `FAILED`
  `result_state` or `INTERNAL_ERROR` `life_cycle_state.` The value -1
  means to retry indefinitely and the value 0 means to never retry. The
  default behavior is to never retry.

- min_retry_interval_millis:

  Optional minimal interval in milliseconds between the start of the
  failed run and the subsequent retry run. The default behavior is that
  unsuccessful runs are immediately retried.

- retry_on_timeout:

  Optional policy to specify whether to retry a task when it times out.
  The default behavior is to not retry on timeout.

- run_if:

  The condition determining whether the task is run once its
  dependencies have been completed.
