# Spark Python Task

Spark Python Task

## Usage

``` r
spark_python_task(python_file, parameters = list())
```

## Arguments

- python_file:

  The URI of the Python file to be executed. DBFS and S3 paths are
  supported.

- parameters:

  List. Command line parameters passed to the Python file. Use Task
  parameter variables to set parameters containing information about job
  runs.

## See also

Other Task Objects:
[`condition_task()`](https://databrickslabs.github.io/brickster/dev/reference/condition_task.md),
[`email_notifications()`](https://databrickslabs.github.io/brickster/dev/reference/email_notifications.md),
[`for_each_task()`](https://databrickslabs.github.io/brickster/dev/reference/for_each_task.md),
[`libraries()`](https://databrickslabs.github.io/brickster/dev/reference/libraries.md),
[`new_cluster()`](https://databrickslabs.github.io/brickster/dev/reference/new_cluster.md),
[`notebook_task()`](https://databrickslabs.github.io/brickster/dev/reference/notebook_task.md),
[`pipeline_task()`](https://databrickslabs.github.io/brickster/dev/reference/pipeline_task.md),
[`python_wheel_task()`](https://databrickslabs.github.io/brickster/dev/reference/python_wheel_task.md),
[`run_job_task()`](https://databrickslabs.github.io/brickster/dev/reference/run_job_task.md),
[`spark_jar_task()`](https://databrickslabs.github.io/brickster/dev/reference/spark_jar_task.md),
[`spark_submit_task()`](https://databrickslabs.github.io/brickster/dev/reference/spark_submit_task.md),
[`sql_file_task()`](https://databrickslabs.github.io/brickster/dev/reference/sql_file_task.md),
[`sql_query_task()`](https://databrickslabs.github.io/brickster/dev/reference/sql_query_task.md)
