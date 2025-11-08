# SQL File Task

SQL File Task

## Usage

``` r
sql_file_task(path, warehouse_id, source = NULL, parameters = NULL)
```

## Arguments

- path:

  Path of the SQL file. Must be relative if the source is a remote Git
  repository and absolute for workspace paths.

- warehouse_id:

  The canonical identifier of the SQL warehouse.

- source:

  Optional location type of the SQL file. When set to `WORKSPACE`, the
  SQL file will be retrieved from the local Databricks workspace. When
  set to `GIT`, the SQL file will be retrieved from a Git repository
  defined in
  [`git_source()`](https://databrickslabs.github.io/brickster/reference/git_source.md)
  If the value is empty, the task will use `GIT` if
  [`git_source()`](https://databrickslabs.github.io/brickster/reference/git_source.md)
  is defined and `WORKSPACE` otherwise.

- parameters:

  Named list of paramters to be used for each run of this job.

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
[`run_job_task()`](https://databrickslabs.github.io/brickster/reference/run_job_task.md),
[`spark_jar_task()`](https://databrickslabs.github.io/brickster/reference/spark_jar_task.md),
[`spark_python_task()`](https://databrickslabs.github.io/brickster/reference/spark_python_task.md),
[`spark_submit_task()`](https://databrickslabs.github.io/brickster/reference/spark_submit_task.md),
[`sql_query_task()`](https://databrickslabs.github.io/brickster/reference/sql_query_task.md)
