# Run Job Task

Run Job Task

## Usage

``` r
run_job_task(job_id, job_parameters, full_refresh = FALSE)
```

## Arguments

- job_id:

  ID of the job to trigger.

- job_parameters:

  Named list, job-level parameters used to trigger job.

- full_refresh:

  If the pipeline should perform a full refresh.

## See also

Other Task Objects:
[`condition_task()`](https://databrickslabs.github.io/brickster/reference/condition_task.md),
[`email_notifications()`](https://databrickslabs.github.io/brickster/reference/email_notifications.md),
[`for_each_task()`](https://databrickslabs.github.io/brickster/reference/for_each_task.md),
[`libraries()`](https://databrickslabs.github.io/brickster/reference/libraries.md),
[`new_cluster()`](https://databrickslabs.github.io/brickster/reference/new_cluster.md),
[`notebook_task()`](https://databrickslabs.github.io/brickster/reference/notebook_task.md),
[`pipeline_task()`](https://databrickslabs.github.io/brickster/reference/pipeline_task.md),
[`python_wheel_task()`](https://databrickslabs.github.io/brickster/reference/python_wheel_task.md),
[`spark_jar_task()`](https://databrickslabs.github.io/brickster/reference/spark_jar_task.md),
[`spark_python_task()`](https://databrickslabs.github.io/brickster/reference/spark_python_task.md),
[`spark_submit_task()`](https://databrickslabs.github.io/brickster/reference/spark_submit_task.md),
[`sql_file_task()`](https://databrickslabs.github.io/brickster/reference/sql_file_task.md),
[`sql_query_task()`](https://databrickslabs.github.io/brickster/reference/sql_query_task.md)
