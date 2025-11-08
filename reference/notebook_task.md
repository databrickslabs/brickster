# Notebook Task

Notebook Task

## Usage

``` r
notebook_task(notebook_path, base_parameters = NULL)
```

## Arguments

- notebook_path:

  The absolute path of the notebook to be run in the Databricks
  workspace. This path must begin with a slash.

- base_parameters:

  Named list of base parameters to be used for each run of this job.

## Details

If the run is initiated by a call to
[`db_jobs_run_now()`](https://databrickslabs.github.io/brickster/reference/db_jobs_run_now.md)
with parameters specified, the two parameters maps are merged. If the
same key is specified in base_parameters and in run-now, the value from
run-now is used.

Use Task parameter variables to set parameters containing information
about job runs.

If the notebook takes a parameter that is not specified in the job’s
`base_parameters` or the run-now override parameters, the default value
from the notebook is used.

Retrieve these parameters in a notebook using `dbutils.widgets.get`.

## See also

Other Task Objects:
[`condition_task()`](https://databrickslabs.github.io/brickster/reference/condition_task.md),
[`email_notifications()`](https://databrickslabs.github.io/brickster/reference/email_notifications.md),
[`for_each_task()`](https://databrickslabs.github.io/brickster/reference/for_each_task.md),
[`libraries()`](https://databrickslabs.github.io/brickster/reference/libraries.md),
[`new_cluster()`](https://databrickslabs.github.io/brickster/reference/new_cluster.md),
[`pipeline_task()`](https://databrickslabs.github.io/brickster/reference/pipeline_task.md),
[`python_wheel_task()`](https://databrickslabs.github.io/brickster/reference/python_wheel_task.md),
[`run_job_task()`](https://databrickslabs.github.io/brickster/reference/run_job_task.md),
[`spark_jar_task()`](https://databrickslabs.github.io/brickster/reference/spark_jar_task.md),
[`spark_python_task()`](https://databrickslabs.github.io/brickster/reference/spark_python_task.md),
[`spark_submit_task()`](https://databrickslabs.github.io/brickster/reference/spark_submit_task.md),
[`sql_file_task()`](https://databrickslabs.github.io/brickster/reference/sql_file_task.md),
[`sql_query_task()`](https://databrickslabs.github.io/brickster/reference/sql_query_task.md)
