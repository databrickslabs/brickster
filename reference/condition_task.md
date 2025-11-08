# Condition Task

Condition Task

## Usage

``` r
condition_task(
  left,
  right,
  op = c("EQUAL_TO", "GREATER_THAN", "GREATER_THAN_OR_EQUAL", "LESS_THAN",
    "LESS_THAN_OR_EQUAL", "NOT_EQUAL")
)
```

## Arguments

- left:

  Left operand of the condition task. Either a string value or a job
  state or parameter reference.

- right:

  Right operand of the condition task. Either a string value or a job
  state or parameter reference.

- op:

  Operator, one of `"EQUAL_TO"`, `"GREATER_THAN"`,
  `"GREATER_THAN_OR_EQUAL"`, `"LESS_THAN"`, `"LESS_THAN_OR_EQUAL"`,
  `"NOT_EQUAL"`

## Details

The task evaluates a condition that can be used to control the execution
of other tasks when the condition_task field is present. The condition
task does not require a cluster to execute and does not support retries
or notifications.

## See also

Other Task Objects:
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
[`sql_file_task()`](https://databrickslabs.github.io/brickster/reference/sql_file_task.md),
[`sql_query_task()`](https://databrickslabs.github.io/brickster/reference/sql_query_task.md)
