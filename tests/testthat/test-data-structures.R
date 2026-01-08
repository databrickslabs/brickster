test_that("job tasks object behaviour", {
  # we don't currently test if inputs to `job_task()` are of the correct type
  # therefore these tests for basic behaviour
  mock_task_a <- job_task(
    task_key = "mock_task_a",
    existing_cluster_id = "mock_cluster",
    task = notebook_task(notebook_path = "MockNotebook")
  )

  mock_task_b <- job_task(
    task_key = "mock_task_b",
    existing_cluster_id = "mock_cluster",
    task = spark_jar_task(main_class_name = "MockClass"),
    depends_on = "mock_task_a"
  )

  expect_s3_class(mock_task_a, c("JobTaskSettings", "list"))
  expect_s3_class(mock_task_b, c("JobTaskSettings", "list"))
  expect_true(is.job_task(mock_task_a))
  expect_true(is.job_task(mock_task_b))

  expect_error(
    job_task(
      task_key = "mock_task_b",
      existing_cluster_id = "mock_cluster",
      task = "MockTask",
      depends_on = "mock_task_a"
    )
  )

  expect_s3_class(
    job_tasks(mock_task_a, mock_task_b),
    c("JobTasks", "list")
  )
  expect_error(job_tasks(mock_task_a, list()))
  expect_error(job_tasks())
})

test_that("task object behaviour", {
  # notebook task
  nb_task <- notebook_task(notebook_path = "MockNotebook")
  expect_s3_class(nb_task, c("NotebookTask", "JobTask"))
  expect_true(is.notebook_task(nb_task))
  expect_true(is.valid_task_type(nb_task))

  # spark jar task
  sj_task <- spark_jar_task(main_class_name = "MockClass")
  expect_s3_class(sj_task, c("SparkJarTask", "JobTask"))
  expect_true(is.spark_jar_task(sj_task))
  expect_true(is.valid_task_type(sj_task))

  # spark python task
  sp_task <- spark_python_task(python_file = "MockPythonScript")
  expect_s3_class(sp_task, c("SparkPythonTask", "JobTask"))
  expect_true(is.spark_python_task(sp_task))
  expect_true(is.valid_task_type(sp_task))

  # spark submit task
  ss_task <- spark_submit_task(parameters = list(a = "A", b = "B"))
  expect_s3_class(ss_task, c("SparkSubmitTask", "JobTask"))
  expect_true(is.spark_submit_task(ss_task))
  expect_true(is.valid_task_type(ss_task))

  # pipeline task
  pl_task <- pipeline_task(pipeline_id = "MockPipelineId")
  expect_s3_class(pl_task, c("PipelineTask", "JobTask"))
  expect_true(is.pipeline_task(pl_task))
  expect_true(is.valid_task_type(pl_task))

  # python wheel task
  pw_task <- python_wheel_task(package_name = "MockPythonWheel")
  expect_s3_class(pw_task, c("PythonWheelTask", "JobTask"))
  expect_true(is.python_wheel_task(pw_task))
  expect_true(is.valid_task_type(pw_task))

  # sql query task
  sq_task <- sql_query_task(
    query_id = "mock_query_id",
    warehouse_id = "mock_warehouse_id",
    parameters = list(a = 1)
  )
  expect_s3_class(sq_task, c("SqlQueryTask", "JobTask"))
  expect_true(is.sql_query_task(sq_task))
  expect_true(is.valid_task_type(sq_task))

  # sql file task
  sf_task <- sql_file_task(
    path = "mock_path",
    warehouse_id = "mock_warehouse_id",
    parameters = list(a = 1)
  )
  expect_s3_class(sf_task, c("SqlFileTask", "JobTask"))
  expect_true(is.sql_file_task(sf_task))
  expect_true(is.valid_task_type(sf_task))

  # for each task
  fe_nb_task <- job_task(
    task_key = "mock_task_a",
    existing_cluster_id = "mock_cluster",
    task = notebook_task(notebook_path = "MockNotebook")
  )

  fe_task <- for_each_task(1:3, task = fe_nb_task, concurrency = 1)
  expect_s3_class(fe_task, c("ForEachTask", "JobTask"))
  expect_true(is.for_each_task(fe_task))
  expect_true(is.valid_task_type(fe_task))

  # run job task
  rj_task <- run_job_task(job_id = "mock_job_id", job_parameters = list(a = 1))
  expect_s3_class(rj_task, c("RunJobTask", "JobTask"))
  expect_true(is.run_job_task(rj_task))
  expect_true(is.valid_task_type(rj_task))

  # condition task
  cnd_task1 <- condition_task(left = "A", right = "B", op = "NOT_EQUAL")
  expect_s3_class(cnd_task1, c("ConditionTask", "JobTask"))
  expect_true(is.condition_task(cnd_task1))
  expect_true(is.valid_task_type(cnd_task1))
  cnd_task2 <- expect_error(condition_task(
    left = "A",
    right = "B",
    op = "SOME_CONDITION"
  ))
})

test_that("library object behaviour", {
  # jar
  jar <- lib_jar(jar = "MockJar.jar")
  expect_s3_class(jar, c("JarLibrary", "Library"))
  expect_true(is.lib_jar(jar))
  expect_true(is.library(jar))

  # egg
  egg <- lib_egg(egg = "s3://mock-bucket/MockEgg")
  expect_s3_class(egg, c("EggLibrary", "Library"))
  expect_true(is.lib_egg(egg))
  expect_true(is.library(egg))

  # wheel
  whl <- lib_whl(whl = "s3://mock-bucket/MockWheel")
  expect_s3_class(whl, c("WhlLibrary", "Library"))
  expect_true(is.lib_whl(whl))
  expect_true(is.library(whl))

  # PyPI
  pypi <- lib_pypi(package = "MockPackage")
  expect_s3_class(pypi, c("PyPiLibrary", "Library"))
  expect_true(is.lib_pypi(pypi))
  expect_true(is.library(pypi))

  # maven
  maven <- lib_maven(coordinates = "org.Mock.Package:0.0.1")
  expect_s3_class(maven, c("MavenLibrary", "Library"))
  expect_true(is.lib_maven(maven))
  expect_true(is.library(maven))

  # cran
  cran <- lib_cran(package = "brickster")
  expect_s3_class(cran, c("CranLibrary", "Library"))
  expect_true(is.lib_cran(cran))
  expect_true(is.library(cran))

  # libraries object
  libs <- libraries(jar, egg, whl, pypi, maven, cran)
  expect_s3_class(libs, c("Libraries", "list"))
  expect_true(is.libraries(libs))
  expect_error(libraries(123))
  expect_error(libraries("MockLibrary"))
  expect_error(libraries("MockLibrary", jar, cran))
})

test_that("access control object behaviour", {
  ## user
  # test all permissions are okay
  valid_permissions <- c("CAN_MANAGE", "CAN_MANAGE_RUN", "CAN_VIEW", "IS_OWNER")
  for (perm in valid_permissions) {
    expect_s3_class(
      cont_req_user <- access_control_req_user(
        user_name = "user@mock.com",
        permission_level = perm
      ),
      class = c("AccessControlRequestForUser", "list")
    )
    expect_true(is.access_control_req_user(cont_req_user))
  }

  # test invalid permissions raise errors
  invalid_permissions <- list(
    "can_manage",
    "mock_permission",
    123,
    123L,
    list(),
    character(0)
  )
  for (perm in invalid_permissions) {
    expect_error(
      access_control_req_user(
        user_name = "user@mock.com",
        permission_level = perm
      )
    )
  }

  ## group
  # test all permissions are okay
  valid_permissions <- c("CAN_MANAGE", "CAN_MANAGE_RUN", "CAN_VIEW")
  for (perm in valid_permissions) {
    expect_s3_class(
      cont_req_grp <- access_control_req_group(
        group = "MockGroup",
        permission_level = perm
      ),
      class = c("AccessControlRequestForUser", "list")
    )
    expect_true(is.access_control_req_group(cont_req_grp))
  }

  # test invalid permissions raise errors
  invalid_permissions <- list(
    "can_manage",
    "mock_permission",
    123,
    123L,
    list(),
    character(0)
  )
  for (perm in invalid_permissions) {
    expect_error(
      access_control_req_group(
        group = "MockGroup",
        permission_level = perm
      )
    )
  }

  # access control request
  group_perm <- access_control_req_group(
    group = "MockGroup",
    permission_level = "CAN_VIEW"
  )
  user_perm <- access_control_req_user(
    user_name = "user@mock.com",
    permission_level = "IS_OWNER"
  )
  expect_s3_class(
    access_control_request(group_perm),
    c("AccessControlRequest", "list")
  )
  expect_s3_class(
    access_control_request(user_perm),
    c("AccessControlRequest", "list")
  )
  expect_s3_class(
    access_control_request(group_perm, user_perm),
    c("AccessControlRequest", "list")
  )
  expect_length(
    access_control_request(group_perm, user_perm),
    2L
  )
  expect_true(
    is.access_control_request(
      access_control_request(group_perm, user_perm)
    )
  )
})


test_that("cron object behaviour", {
  # we do not check validity of CRON expression or timezone
  # these checks are made via API which provides appropriate response and error
  valid_status <- c("UNPAUSED", "PAUSED")
  for (status in valid_status) {
    expect_s3_class(
      cron <- cron_schedule(
        quartz_cron_expression = "* * * 5 *",
        timezone_id = "Etc/UTC",
        pause_status = status
      ),
      c("CronSchedule", "list")
    )
    expect_true(is.cron_schedule(cron))
  }

  invalid_status <- c("paused", "active", 123L, 123, character(0))
  for (status in invalid_status) {
    expect_error(
      cron_schedule(
        quartz_cron_expression = "* * * 5 *",
        timezone_id = "Etc/UTC",
        pause_status = status
      )
    )
  }
})

test_that("email notification object behaviour", {
  # test that inputs are invalid types
  allowed <- "user@mock.com"
  not_allowed_on <- list(list(), 123L, 123)
  not_allowed_alert <- list(list(), 123L, 123, "mock", character(0))

  for (input in not_allowed_on) {
    expect_error(
      email_notifications(
        on_start = not_allowed_on,
        on_success = not_allowed_on,
        on_failure = not_allowed_on
      )
    )
  }

  for (input in not_allowed_alert) {
    expect_error(
      email_notifications(
        on_start = allowed,
        on_success = allowed,
        on_failure = allowed,
        no_alert_for_skipped_runs = input
      )
    )
  }

  # test that valid inputs don't error
  expect_s3_class(
    email_notif <- email_notifications(
      on_start = allowed,
      on_success = allowed,
      on_failure = allowed
    ),
    c("JobEmailNotifications", "list")
  )
  expect_true(is.email_notifications(email_notif))

  expect_s3_class(
    email_notif2 <- email_notifications(
      on_start = allowed,
      on_success = allowed,
      on_failure = allowed,
      no_alert_for_skipped_runs = FALSE
    ),
    c("JobEmailNotifications", "list")
  )
  expect_true(is.email_notifications(email_notif2))
})


test_that("cluster objects behaviour", {
  # cluster autoscale
  expect_s3_class(
    autoscale <- cluster_autoscale(min_workers = 2, max_workers = 4),
    c("AutoScale", "list")
  )
  expect_true(is.cluster_autoscale(autoscale))

  expect_error(cluster_autoscale(min_workers = 2, max_workers = 0))
  expect_error(cluster_autoscale(min_workers = 2, max_workers = 2))
  expect_error(cluster_autoscale(min_workers = -2, max_workers = 2))
  expect_error(cluster_autoscale(min_workers = 2))
  expect_error(cluster_autoscale(max_workers = 2))

  # dbfs storage
  expect_s3_class(
    dbfs <- dbfs_storage_info(destination = "/mock/storage/path"),
    c("DbfsStorageInfo", "list")
  )
  expect_true(is.dbfs_storage_info(dbfs))

  # file storage
  expect_s3_class(
    fs <- file_storage_info(destination = "/mock/storage/path"),
    c("DbfsStorageInfo", "list")
  )
  expect_true(is.file_storage_info(fs))

  # s3 storage info
  expect_s3_class(
    s3 <- s3_storage_info(
      destination = "s3://mock/bucket/path",
      region = "ap-southeast-2"
    ),
    c("S3StorageInfo", "list")
  )
  expect_true(is.s3_storage_info(s3))
  expect_error(
    s3_storage_info(
      destination = "s3://mock/bucket/path",
      region = "ap-southeast-2",
      encryption_type = "mock_encrypton"
    )
  )
  expect_length(
    s3_storage_info(
      destination = "s3://mock/bucket/path",
      region = "ap-southeast-2",
      encryption_type = c("sse-s3", "sse-kms")
    )$encryption_type,
    1
  )

  # cluster log conf
  expect_s3_class(
    clc_dbfs <- cluster_log_conf(dbfs = dbfs),
    c("ClusterLogConf", "list")
  )
  expect_true(is.cluster_log_conf(clc_dbfs))

  expect_s3_class(
    clc_s3 <- cluster_log_conf(s3 = s3),
    c("ClusterLogConf", "list")
  )
  expect_true(is.cluster_log_conf(clc_s3))

  expect_error(cluster_log_conf(dbfs = dbfs, s3 = s3))
  expect_error(cluster_log_conf(s3 = dbfs))
  expect_error(cluster_log_conf(dbfs = s3))
  expect_error(cluster_log_conf(dbfs = fs))
  expect_error(cluster_log_conf(s3 = fs))
  expect_error(cluster_log_conf())

  # docker image
  mock_image <- docker_image("mock_url", "mock_user", "mock_pass")
  expect_s3_class(mock_image, c("DockerImage", "list"))
  expect_true(is.docker_image(mock_image))
  expect_false(is.docker_image(list()))
  expect_error(docker_image())
  expect_error(docker_image(list()))

  # init script
  expect_s3_class(
    init <- init_script_info(s3, dbfs, fs),
    c("InitScriptInfo", "list")
  )
  expect_s3_class(
    init_script_info(),
    c("InitScriptInfo", "list")
  )
  expect_true(is.init_script_info(init))

  expect_error(init_script_info(1))
  expect_error(init_script_info("a"))
  expect_error(init_script_info(fs, 1))

  ## cloud attributes
  # gcp
  expect_s3_class(gcp_attributes(), c("GcpAttributes", "list"))
  expect_true(is.gcp_attributes(gcp_attributes()))

  # aws
  expect_s3_class(aws_attributes(), c("AwsAttributes", "list"))
  expect_true(is.aws_attributes(aws_attributes()))

  # azure
  expect_s3_class(azure_attributes(), c("AzureAttributes", "list"))
  expect_true(is.azure_attributes(azure_attributes()))
  expect_error(azure_attributes(first_on_demand = -1))
  expect_error(azure_attributes(first_on_demand = 0))

  # new cluster
  # TODO: add more checks, but should add more logic to `new_cluster()`
  cloud_attr_types <- list(
    aws_attributes(),
    gcp_attributes(),
    azure_attributes()
  )

  for (cloud in cloud_attr_types) {
    cluster <- new_cluster(
      num_workers = 1,
      spark_version = "mock_spark_version",
      node_type_id = "mock_node_type_id",
      driver_node_type_id = "mock_driver_node_type_id",
      cloud_attrs = cloud
    )
    expect_s3_class(cluster, c("NewCluster", "list"))
    expect_true(is.new_cluster(cluster))
  }

  expect_error(
    new_cluster(
      num_workers = 1,
      spark_version = "mock_spark_version",
      node_type_id = "mock_node_type_id",
      driver_node_type_id = "mock_driver_node_type_id",
      cloud_attrs = list()
    )
  )
})

test_that("git_source behaviour", {
  gs_git_tag <- git_source(
    git_url = "mockUrl",
    git_provider = "github",
    reference = "a",
    type = "tag"
  )

  gs_git_branch <- git_source(
    git_url = "mockUrl",
    git_provider = "github",
    reference = "a",
    type = "branch"
  )

  gs_git_commit <- git_source(
    git_url = "mockUrl",
    git_provider = "github",
    reference = "a",
    type = "commit"
  )

  expect_s3_class(gs_git_tag, c("GitSource", "list"))
  expect_s3_class(gs_git_branch, c("GitSource", "list"))
  expect_s3_class(gs_git_commit, c("GitSource", "list"))

  expect_true(is.git_source(gs_git_tag))
  expect_true(is.git_source(gs_git_branch))
  expect_true(is.git_source(gs_git_commit))

  expect_error(
    git_source(
      git_url = "mockUrl",
      git_provider = "fake",
      reference = "a",
      type = "commit"
    )
  )

  expect_error(
    git_source(
      git_provider = "fake",
      reference = "a",
      type = "commit"
    )
  )

  expect_error(
    git_source(
      git_url = "mockUrl",
      reference = "a",
      type = "commit"
    )
  )

  expect_error(git_source())
})

test_that("vector search behaviour", {
  esc <- embedding_source_column(
    name = "mockColumnName",
    model_endpoint_name = "mockEndpointName"
  )
  expect_s3_class(esc, c("EmbeddingSourceColumn", "list"))
  expect_true(is.embedding_source_column(esc))
  expect_error(embedding_source_column())

  evc <- embedding_vector_column(
    name = "mockColumnName",
    dimension = 256
  )
  expect_s3_class(evc, c("EmbeddingVectorColumn", "list"))
  expect_true(is.embedding_vector_column(evc))
  expect_error(embedding_vector_column())
  expect_error(embedding_vector_column(name = "mockColumn", dimension = "64"))

  ds_index <- delta_sync_index_spec(
    source_table = "mock.table.name",
    embedding_writeback_table = "mock_writeback_table",
    embedding_source_columns = esc,
    embedding_vector_columns = evc,
    pipeline_type = "TRIGGERED"
  )
  expect_s3_class(
    ds_index,
    c("VectorSearchIndexSpec", "DeltaSyncIndex", "list")
  )
  expect_true(is.vector_search_index_spec(ds_index))
  expect_true(is.delta_sync_index(ds_index))
  expect_error(delta_sync_index_spec())

  # pipeline type must be valid
  expect_error({
    delta_sync_index_spec(
      source_table = "mock.table.name",
      embedding_writeback_table = "mock_writeback_table",
      embedding_source_columns = esc,
      embedding_vector_columns = evc,
      pipeline_type = "MOCK"
    )
  })

  # must have a vector or source column specified - cant all be NULL
  expect_error({
    delta_sync_index_spec(
      source_table = "mock.table.name",
      embedding_writeback_table = "mock_writeback_table",
      embedding_source_columns = NULL,
      embedding_vector_columns = NULL,
      pipeline_type = "TRIGGERED"
    )
  })

  da_index <- direct_access_index_spec(
    embedding_source_columns = esc,
    embedding_vector_columns = evc,
    schema = list("mock_col_a" = "integer")
  )
  expect_s3_class(
    da_index,
    c("VectorSearchIndexSpec", "DirectAccessIndex", "list")
  )
  expect_true(is.vector_search_index_spec(da_index))
  expect_true(is.direct_access_index(da_index))
  expect_error(direct_access_index_spec())

  # schema must be named list
  expect_error({
    direct_access_index_spec(
      embedding_source_columns = esc,
      embedding_vector_columns = evc,
      schema = list("integer")
    )
  })

  expect_error({
    direct_access_index_spec(
      embedding_source_columns = esc,
      embedding_vector_columns = evc,
      schema = NULL
    )
  })

  # must have a vector or source column specified - cant all be NULL
  expect_error({
    direct_access_index_spec(
      embedding_source_columns = NULL,
      embedding_vector_columns = NULL,
      schema = list("mock_col_a" = "integer")
    )
  })
})
