# Job Management

## Managing Databricks Jobs

[brickster](https://github.com/databrickslabs/brickster) provides
coverage of the Jobs REST API’s, allowing creation of multi-task jobs
via R code.

### Job Basics

When listing the jobs the default behaviour is to returns the first 25
jobs, to configure the number of jobs returned you can specify `limit`
and `offset`.

The `expand_tasks` parameter will return task and cluster details for
each job (default `FALSE)`.

``` r
# list all jobs within Databricks workspace
# can control limit, offset, and if cluster/jobs details are returned
jobs <- db_jobs_list(limit = 10)

# list all runs within a specific job
job_runs <- db_jobs_runs_list(job_id = jobs[[1]]$job_id)
```

To return the details of a specific job you can use
[`db_jobs_get()`](https://databrickslabs.github.io/brickster/reference/db_jobs_get.md),
this requires knowledge of the `job_id` which can be found via the user
interface in Databricks or using
[`db_jobs_list()`](https://databrickslabs.github.io/brickster/reference/db_jobs_list.md).

``` r
# details of a specific job
job_details <- db_jobs_get(job_id = jobs[[1]]$job_id)
```

Each job has one or more tasks which may have dependence upon each
other, execution of a job will flow through these tasks - this is known
as a “run” of a job. Jobs can be scheduled to start a run on a
particular schedule, or by a direct trigger such as
[`db_jobs_run_now()`](https://databrickslabs.github.io/brickster/reference/db_jobs_run_now.md).

There are a number of functions that are specific to job runs execution
and metadata:

|                                   Purpose |                                                    Function                                                    |
|------------------------------------------:|:--------------------------------------------------------------------------------------------------------------:|
|        Trigger new run of an existing job |         [`db_jobs_run_now()`](https://databrickslabs.github.io/brickster/reference/db_jobs_run_now.md)         |
|                        List runs of a job |       [`db_jobs_runs_list()`](https://databrickslabs.github.io/brickster/reference/db_jobs_runs_list.md)       |
|  Retrieve metadata for a specific job run |        [`db_jobs_runs_get()`](https://databrickslabs.github.io/brickster/reference/db_jobs_runs_get.md)        |
| Retrieve metadata for a specific task run | [`db_jobs_runs_get_output()`](https://databrickslabs.github.io/brickster/reference/db_jobs_runs_get_output.md) |
| Export code and/or dashboard for task run |     [`db_jobs_runs_export()`](https://databrickslabs.github.io/brickster/reference/db_jobs_runs_export.md)     |
|                Delete record of a job run |     [`db_jobs_runs_delete()`](https://databrickslabs.github.io/brickster/reference/db_jobs_runs_delete.md)     |
|                       Cancel run of a job |     [`db_jobs_runs_cancel()`](https://databrickslabs.github.io/brickster/reference/db_jobs_runs_cancel.md)     |

When using functions such as `db_jobs_run_get_output()` and
[`db_jobs_runs_export()`](https://databrickslabs.github.io/brickster/reference/db_jobs_runs_export.md)
the required `run_id` can refer to the id of a given task. Each task
within a given “run” will also have a `run_id` that can be referenced.

### Creating Jobs

[brickster](https://github.com/databrickslabs/brickster) enables
creation of jobs from R, these jobs can be simple single task jobs or
complex multi-task jobs with dependencies that share and re-use
clusters.

#### Simple Job

A single-task job can be created with the following components:

- [`job_task()`](https://databrickslabs.github.io/brickster/reference/job_task.md)
  which defines a singular task

- [`new_cluster()`](https://databrickslabs.github.io/brickster/reference/new_cluster.md)
  required by
  [`job_task()`](https://databrickslabs.github.io/brickster/reference/job_task.md),
  it defines the compute specifications

- `*_task()`, one of the task functions
  e.g. [`notebook_task()`](https://databrickslabs.github.io/brickster/reference/notebook_task.md)

Below is the creation of a simple job that runs a notebook and has a
paused schedule:

``` r
# define a job task
simple_task <- job_task(
  task_key = "simple_task",
  description = "a simple task that runs a notebook",
  # specify a cluster for the job
  new_cluster = new_cluster(
    spark_version = "16.4.x-scala2.12",
    driver_node_type_id = "m5a.large",
    node_type_id = "m5a.large",
    num_workers = 2,
    cloud_attr = aws_attributes(ebs_volume_size = 32)
  ),
  # this task will be a notebook
  task = notebook_task(notebook_path = "/brickster/simple-notebook")
)
```

``` r
# create job with simple task
simple_task_job <- db_jobs_create(
  name = "brickster example: simple",
  tasks = job_tasks(simple_task),
  # 9am every day, paused currently
  schedule = cron_schedule(
    quartz_cron_expression = "0 0 9 * * ?",
    pause_status = "PAUSED"
  )
)
```

#### Multiple Tasks

Jobs can be extended beyond a singular task, this next example extends
the simple job example by now having three tasks. Each subsequent task
depends on the priors completion before it can proceed, each task also
will define its own `new_cluster`.

Whilst this job runs the same notebook each time for the sake of example
it demonstrates how to build dependencies.

``` r
# one cluster definition, repeatedly use for each task
multitask_cluster <- new_cluster(
  spark_version = "16.4.x-scala2.12",
  driver_node_type_id = "m5a.large",
  node_type_id = "m5a.large",
  num_workers = 2,
  cloud_attr = aws_attributes(ebs_volume_size = 32)
)

# each task will run the same notebook (just for this example)
multitask_task <- notebook_task(notebook_path = "/brickster/simple-notebook")

# create three simple tasks that will depend on each other
# task_a -> task_b -> task_c
task_a <- job_task(
  task_key = "task_a",
  description = "First task in the sequence",
  new_cluster = multitask_cluster,
  task = multitask_task
)

task_b <- job_task(
  task_key = "task_b",
  description = "Second task in the sequence",
  new_cluster = multitask_cluster,
  task = multitask_task,
  depends_on = "task_a"
)

task_c <- job_task(
  task_key = "task_c",
  description = "Third task in the sequence",
  new_cluster = multitask_cluster,
  task = multitask_task,
  depends_on = "task_b"
)
```

``` r
# create job with multiple tasks
multitask_job <- db_jobs_create(
  name = "brickster example: multi-task",
  tasks = job_tasks(task_a, task_b, task_c),
  # 9am every day, paused currently
  schedule = cron_schedule(
    quartz_cron_expression = "0 0 9 * * ?",
    pause_status = "PAUSED"
  )
)
```

#### Cluster Reuse

The multiple tasks example has one shortcoming - clusters are not reused
between tasks and therefore each task will have to wait for another
cluster to be started before its computations can begin, this will
typically add a few minutes to each task.

It can be advantageous to reuse clusters between job tasks to avoid
overhead for short lived tasks, or to share resources for tasks which
are not computationally demanding.

This example is the same as the previous multi-task job however it now
shares a single cluster for each task.

`new_cluster` is replaced with `job_cluster_key` in each task:

``` r
# create three simple tasks that will depend on each other
# this time we will use a shared cluster to reduce startup overhead
# task_a -> task_b -> task_c
task_a <- job_task(
  task_key = "task_a",
  description = "First task in the sequence",
  job_cluster_key = "shared_cluster",
  task = multitask_task
)

task_b <- job_task(
  task_key = "task_b",
  description = "Second task in the sequence",
  job_cluster_key = "shared_cluster",
  task = multitask_task,
  depends_on = "task_a"
)

task_c <- job_task(
  task_key = "task_c",
  description = "Third task in the sequence",
  job_cluster_key = "shared_cluster",
  task = multitask_task,
  depends_on = "task_b"
)
```

`job_clusters` is now defined in the
[`db_jobs_create()`](https://databrickslabs.github.io/brickster/reference/db_jobs_create.md)
call where it accepts a named list of `new_clusters()`, we will reuse
our example from earlier:

``` r
# define job_clusters as a named list of new_cluster()
multitask_job_with_reuse <- db_jobs_create(
  name = "brickster example: multi-task with reuse",
  job_clusters = list("shared_cluster" = multitask_cluster),
  tasks = job_tasks(task_a, task_b, task_c),
  # 9am every day, paused currently
  schedule = cron_schedule(
    quartz_cron_expression = "0 0 9 * * ?",
    pause_status = "PAUSED"
  )
)
```

There can be multiple shared clusters and it may be beneficial to give
some demanding tasks a larger cluster alone (or to share with other
demanding tasks).

#### One-off Jobs

It’s possible to create one-off jobs that do not have a schedule and
only appears under the “jobs runs” tab, not “jobs”.
[`db_jobs_runs_submit()`](https://databrickslabs.github.io/brickster/reference/db_jobs_runs_submit.md)
permits the use of an `idempotency_token` which can avoid re-submission
of a run.

``` r
# submit a one off job run
# reuse the simple task from first example
# idempotency_token guarentees no additional triggers
oneoff_job <- db_jobs_runs_submit(
  tasks = job_tasks(simple_task),
  run_name = "brickster example: one-off job",
  idempotency_token = "my_job_run_token"
)
```

#### Remote Git Repos

Instead of using notebooks contained within the Databricks workspace a
job can be referenced in an external git repository and reference a
specific branch, tag, or commit.

Let’s revisit the simple job example from before and adjust to use
[`git_source()`](https://databrickslabs.github.io/brickster/reference/git_source.md).  
In this example the repo will have a folder `example` which contains
`simple-notebook.py`.

``` r
# define a job task
# this time, the notebook_path is relative to the git root directory
# omit file extensions like .py or .r
simple_task <- job_task(
  task_key = "simple_task",
  description = "a simple task that runs a notebook",
  # specify a cluster for the job
  new_cluster = new_cluster(
    spark_version = "16.4.x-scala2.12",
    driver_node_type_id = "m5a.large",
    node_type_id = "m5a.large",
    num_workers = 2,
    cloud_attr = aws_attributes(ebs_volume_size = 32)
  ),
  # this task will be a notebook
  task = notebook_task(notebook_path = "example/simple-notebook")
)
```

Within the call to
[`db_jobs_create()`](https://databrickslabs.github.io/brickster/reference/db_jobs_create.md)
use
[`git_source()`](https://databrickslabs.github.io/brickster/reference/git_source.md)
to point to the repo containing the notebook.

``` r
# create job with simple task
simple_task_job <- db_jobs_create(
  name = "brickster example: simple",
  tasks = job_tasks(simple_task),
  # git source points to repo
  git_source = git_source(
    git_url = "www.github.com/<user>/<repo>",
    git_provider = "github",
    reference = "main",
    type = "branch"
  ),
  # 9am every day, paused currently
  schedule = cron_schedule(
    quartz_cron_expression = "0 0 9 * * ?",
    pause_status = "PAUSED"
  )
)
```

### Updating Jobs

#### Partial Update

Jobs can be partially updated, for example to rename an existing job:

``` r
# only change the job name
db_jobs_update(
  job_id = multitask_job_with_reuse$job_id,
  name = "brickster example: renamed job"
)
```

Adding a timeout and adjusting maximum concurrent runs allowed:

``` r
# adding timeout and increasing max concurrent runs
db_jobs_update(
  job_id = multitask_job_with_reuse$job_id,
  timeout_seconds = 60 * 5,
  max_concurrent_runs = 2
)
```

You can add new tasks but it may involve some extra steps, either:

- Having
  [`job_task()`](https://databrickslabs.github.io/brickster/reference/job_task.md)
  required for job defined already within R and adding new tasks

- Specifying all
  [`job_task()`](https://databrickslabs.github.io/brickster/reference/job_task.md)’s
  again

- Using
  [`db_jobs_get()`](https://databrickslabs.github.io/brickster/reference/db_jobs_get.md)
  and parsing the returned metadata into
  [`job_task()`](https://databrickslabs.github.io/brickster/reference/job_task.md)’s

#### Complete Update

A complete overwrite of a job can be done with
[`db_jobs_reset()`](https://databrickslabs.github.io/brickster/reference/db_jobs_reset.md) -
this allows the `job_id` to remain constant while maintaining the
historical run information with prior settings.
[`db_jobs_reset()`](https://databrickslabs.github.io/brickster/reference/db_jobs_reset.md)
is the same as
[`db_jobs_create()`](https://databrickslabs.github.io/brickster/reference/db_jobs_create.md)
except it takes one additional parameter (`job_id`).

### Managing Jobs

[`db_jobs_list()`](https://databrickslabs.github.io/brickster/reference/db_jobs_list.md)
and
[`db_jobs_runs_list()`](https://databrickslabs.github.io/brickster/reference/db_jobs_runs_list.md)
were covered in [job basics](#job-basics).

#### Invocation

Jobs can be triggered by:

- Their defined schedule (see:
  [`cron_schedule()`](https://databrickslabs.github.io/brickster/reference/cron_schedule.md))

- Using
  [`db_jobs_run_now()`](https://databrickslabs.github.io/brickster/reference/db_jobs_run_now.md)
  to trigger a run outside regular schedule or on a paused job.

- Creating a one off job run via
  [`db_jobs_runs_submit()`](https://databrickslabs.github.io/brickster/reference/db_jobs_runs_submit.md)

The only example yet to be covered is
[`db_jobs_run_now()`](https://databrickslabs.github.io/brickster/reference/db_jobs_run_now.md),
it accepts parameters as named lists:

``` r
# invoke simple job example
triggered_run <- db_jobs_run_now(job_id = simple_task_job$job_id)
```

Runs can also be cancelled:

``` r
# cancel run whilst it is in progress
db_jobs_runs_cancel(run_id = triggered_run$run_id)
```

#### Deletion

Jobs and runs can be deleted with
[`db_jobs_delete()`](https://databrickslabs.github.io/brickster/reference/db_jobs_delete.md)
and
[`db_jobs_runs_delete()`](https://databrickslabs.github.io/brickster/reference/db_jobs_runs_delete.md)
respectively.

Cleaning up all jobs created in this documentation:

``` r
db_jobs_delete(job_id = simple_task_job$job_id)
db_jobs_delete(job_id = multitask_job$job_id)
db_jobs_delete(job_id = multitask_job_with_reuse$job_id)
```
