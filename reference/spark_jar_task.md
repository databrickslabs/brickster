# Spark Jar Task

Spark Jar Task

## Usage

``` r
spark_jar_task(main_class_name, parameters = list())
```

## Arguments

- main_class_name:

  The full name of the class containing the main method to be executed.
  This class must be contained in a JAR provided as a library. The code
  must use `SparkContext.getOrCreate` to obtain a Spark context;
  otherwise, runs of the job fail.

- parameters:

  Named list. Parameters passed to the main method. Use Task parameter
  variables to set parameters containing information about job runs.

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
[`spark_python_task()`](https://databrickslabs.github.io/brickster/reference/spark_python_task.md),
[`spark_submit_task()`](https://databrickslabs.github.io/brickster/reference/spark_submit_task.md),
[`sql_file_task()`](https://databrickslabs.github.io/brickster/reference/sql_file_task.md),
[`sql_query_task()`](https://databrickslabs.github.io/brickster/reference/sql_query_task.md)
