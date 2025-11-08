# Cron Schedule

Cron Schedule

## Usage

``` r
cron_schedule(
  quartz_cron_expression,
  timezone_id = "Etc/UTC",
  pause_status = c("UNPAUSED", "PAUSED")
)
```

## Arguments

- quartz_cron_expression:

  Cron expression using Quartz syntax that describes the schedule for a
  job. See [Cron
  Trigger](https://www.quartz-scheduler.org/documentation/quartz-2.3.0/tutorials/crontrigger.html)
  for details.

- timezone_id:

  Java timezone ID. The schedule for a job is resolved with respect to
  this timezone. See [Java
  TimeZone](https://docs.oracle.com/javase/7/docs/api/java/util/TimeZone.html)
  for details.

- pause_status:

  Indicate whether this schedule is paused or not. Either `UNPAUSED`
  (default) or `PAUSED`.

## See also

[`db_jobs_create()`](https://databrickslabs.github.io/brickster/reference/db_jobs_create.md),
[`db_jobs_reset()`](https://databrickslabs.github.io/brickster/reference/db_jobs_reset.md),
[`db_jobs_update()`](https://databrickslabs.github.io/brickster/reference/db_jobs_update.md)
