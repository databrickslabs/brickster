test_that("Jobs API - don't perform", {
  withr::local_envvar(c(
    "DATABRICKS_HOST" = "http://mock_host",
    "DATABRICKS_TOKEN" = "mock_token"
  ))

  resp_list <- db_jobs_list(
    perform_request = F
  )
  expect_s3_class(resp_list, "httr2_request")

  # define a job task
  simple_task <- job_task(
    task_key = "simple_task",
    description = "a simple task that runs a notebook",
    # specify a cluster for the job
    new_cluster = new_cluster(
      spark_version = "9.1.x-scala2.12",
      driver_node_type_id = "m5a.large",
      node_type_id = "m5a.large",
      num_workers = 2,
      cloud_attrs = aws_attributes(ebs_volume_size = 32)
    ),
    # this task will be a notebook
    task = notebook_task(notebook_path = "/brickster/simple-notebook")
  )

  job_clusters <- list(
    "simple_cluster" = new_cluster(
      spark_version = "mock_runtime",
      driver_node_type_id = "m5a.large",
      node_type_id = "m5a.large",
      num_workers = 2,
      cloud_attr = aws_attributes(ebs_volume_size = 32),
      data_security_mode = "DATA_SECURITY_MODE_AUTO"
    )
  )

  # create job with simple task
  resp_create <- db_jobs_create(
    name = "brickster example: simple",
    tasks = job_tasks(simple_task),
    # 9am every day, paused currently
    schedule = cron_schedule(
      quartz_cron_expression = "0 0 9 * * ?",
      pause_status = "PAUSED"
    ),
    job_clusters = job_clusters,
    perform_request = F
  )
  expect_s3_class(resp_create, "httr2_request")

  resp_delete <- db_jobs_delete(
    job_id = "some_job_id",
    perform_request = F
  )
  expect_s3_class(resp_delete, "httr2_request")

  resp_get <- db_jobs_get(
    job_id = "some_job_id",
    perform_request = F
  )
  expect_s3_class(resp_get, "httr2_request")

  resp_update <- db_jobs_update(
    job_id = "some_job_id",
    name = "brickster example: renamed job",
    perform_request = F
  )
  expect_s3_class(resp_update, "httr2_request")

  resp_reset <- db_jobs_reset(
    job_id = "some_job_id",
    name = "brickster example: reset job",
    tasks = job_tasks(simple_task),
    schedule = cron_schedule(
      quartz_cron_expression = "0 0 9 * * ?",
      pause_status = "PAUSED"
    ),
    job_clusters = job_clusters,
    perform_request = F
  )
  expect_s3_class(resp_reset, "httr2_request")

  resp_run_now <- db_jobs_run_now(
    job_id = "some_job_id",
    perform_request = F
  )
  expect_s3_class(resp_run_now, "httr2_request")

  resp_run_cancel <- db_jobs_runs_cancel(
    run_id = "some_run_id",
    perform_request = F
  )
  expect_s3_class(resp_run_cancel, "httr2_request")

  resp_run_del <- db_jobs_runs_delete(
    run_id = "some_run_id",
    perform_request = F
  )
  expect_s3_class(resp_run_del, "httr2_request")

  resp_run_export <- db_jobs_runs_export(
    run_id = "some_run_id",
    perform_request = F
  )
  expect_s3_class(resp_run_export, "httr2_request")

  resp_run_get <- db_jobs_runs_get(
    run_id = "some_run_id",
    perform_request = F
  )
  expect_s3_class(resp_run_get, "httr2_request")

  resp_run_get_output <- db_jobs_runs_get_output(
    run_id = "some_run_id",
    perform_request = F
  )
  expect_s3_class(resp_run_get_output, "httr2_request")

  resp_run_list <- db_jobs_runs_list(
    job_id = "some_job_id",
    perform_request = F
  )
  expect_s3_class(resp_run_list, "httr2_request")
  expect_error({
    resp_run_list <- db_jobs_runs_list(
      job_id = "some_job_id",
      active_only = TRUE,
      completed_only = TRUE,
      perform_request = F
    )
  })

  resp_run_submit <- db_jobs_runs_submit(
    tasks = job_tasks(simple_task),
    run_name = "brickster example: one-off job",
    idempotency_token = "my_job_run_token",
    perform_request = F
  )
  expect_s3_class(resp_run_submit, "httr2_request")

  # Test db_jobs_repair_run
  resp_repair_run <- db_jobs_repair_run(
    run_id = "some_run_id",
    rerun_tasks = c("task1", "task2"),
    job_parameters = list(param1 = "value1"),
    perform_request = F
  )
  expect_s3_class(resp_repair_run, "httr2_request")

  # Test with rerun_all_failed_tasks
  resp_repair_all <- db_jobs_repair_run(
    run_id = "some_run_id",
    rerun_all_failed_tasks = TRUE,
    rerun_dependent_tasks = TRUE,
    perform_request = F
  )
  expect_s3_class(resp_repair_all, "httr2_request")

  # Test with performance target
  resp_repair_perf <- db_jobs_repair_run(
    run_id = "some_run_id",
    rerun_tasks = c("task1"),
    performance_target = "PERFORMANCE_OPTIMIZED",
    pipeline_full_refresh = TRUE,
    latest_repair_id = "repair_123",
    perform_request = F
  )
  expect_s3_class(resp_repair_perf, "httr2_request")

  # Test error when both rerun_tasks and rerun_all_failed_tasks are specified
  expect_error({
    db_jobs_repair_run(
      run_id = "some_run_id",
      rerun_tasks = c("task1"),
      rerun_all_failed_tasks = TRUE,
      perform_request = F
    )
  })

  # Test error for invalid performance_target
  expect_error({
    db_jobs_repair_run(
      run_id = "some_run_id",
      rerun_tasks = c("task1"),
      performance_target = "INVALID_TARGET",
      perform_request = F
    )
  })
})

skip_on_cran()
skip_unless_authenticated()
skip_unless_aws_workspace()

test_that("Jobs API", {
  # define a job task
  resp_list_dbrv <- db_cluster_runtime_versions()
  # use a standard runtime
  runtimes <- base::sort(
    purrr::map_chr(resp_list_dbrv$versions, "key"),
    decreasing = TRUE
  )
  std_runtimes <- purrr::keep(runtimes, ~ !grepl("photon|gpu", .x))
  job_clusters <- list(
    "simple_cluster" = new_cluster(
      spark_version = std_runtimes[1],
      driver_node_type_id = "m5a.large",
      node_type_id = "m5a.large",
      num_workers = 2,
      cloud_attr = aws_attributes(ebs_volume_size = 32),
      data_security_mode = "DATA_SECURITY_MODE_AUTO"
    )
  )

  simple_task <- job_task(
    task_key = "simple_task",
    description = "a simple task that runs a notebook",
    # specify a cluster for the job
    job_cluster_key = "simple_cluster",
    # this task will be a notebook
    task = notebook_task(
      notebook_path = "/brickster/simple-notebook",
      base_parameters = list(a = 1)
    )
  )

  expect_no_error({
    resp_list <- db_jobs_list()
  })
  expect_type(resp_list, "list")

  expect_no_error({
    resp_create <- db_jobs_create(
      name = "brickster example: simple",
      tasks = job_tasks(simple_task),
      # 9am every day, paused currently
      schedule = cron_schedule(
        quartz_cron_expression = "0 0 9 * * ?",
        pause_status = "PAUSED"
      ),
      job_clusters = job_clusters
    )
  })
  expect_type(resp_create, "list")
  expect_true(!is.null(resp_create$job_id))

  expect_no_error({
    resp_update <- db_jobs_update(
      job_id = resp_create$job_id,
      name = "brickster example: renamed job",
    )
  })
  expect_type(resp_update, "list")

  expect_no_error({
    resp_get <- db_jobs_get(
      job_id = resp_create$job_id
    )
  })
  expect_type(resp_get, "list")
  expect_identical(resp_get$settings$name, "brickster example: renamed job")

  expect_no_error({
    resp_reset <- db_jobs_reset(
      job_id = resp_create$job_id,
      name = "brickster example: reset job",
      tasks = job_tasks(simple_task),
      schedule = cron_schedule(
        quartz_cron_expression = "0 0 9 * * ?",
        pause_status = "PAUSED"
      ),
      job_clusters = job_clusters
    )
  })
  expect_type(resp_reset, "list")

  # `db_jobs_get` again to validate reset behaviour
  expect_no_error({
    resp_get <- db_jobs_get(
      job_id = resp_create$job_id
    )
  })
  expect_type(resp_get, "list")
  expect_identical(resp_get$settings$name, "brickster example: reset job")

  expect_no_error({
    resp_run_get <- db_jobs_runs_list(job_id = resp_create$job_id)
  })
  expect_null(resp_run_get)

  expect_no_error({
    resp_delete <- db_jobs_delete(
      job_id = resp_create$job_id
    )
  })
  expect_type(resp_get, "list")
})
