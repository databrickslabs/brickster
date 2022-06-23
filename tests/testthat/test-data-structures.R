test_that("job tasks object behaviour", {

  # we don't currently test if inputs to `job_task()` are of the correct type
  # therefore these tests for basic behaviour
  mock_task_a <- brickster::job_task(
    task_key = "mock_task_a",
    existing_cluster_id = "mock_cluster",
    task = brickster::notebook_task(notebook_path = "MockNotebook")
  )

  mock_task_b <- brickster::job_task(
    task_key = "mock_task_b",
    existing_cluster_id = "mock_cluster",
    task = brickster::spark_jar_task(main_class_name = "MockClass"),
    depends_on = c("mock_task_a")
  )

  expect_s3_class(mock_task_a, c("JobTaskSettings", "list"))
  expect_s3_class(mock_task_b, c("JobTaskSettings", "list"))
  expect_true(brickster::is.job_task(mock_task_a))
  expect_true(brickster::is.job_task(mock_task_b))

  expect_error(
    brickster::job_task(
      task_key = "mock_task_b",
      existing_cluster_id = "mock_cluster",
      task = "MockTask",
      depends_on = c("mock_task_a")
    )
  )

  expect_s3_class(
    brickster::job_tasks(mock_task_a, mock_task_b),
    c("JobTasks", "list")
  )
  expect_error(brickster::job_tasks(mock_task_a, list()))
  expect_error(brickster::job_tasks())

})

test_that("task object behaviour", {

  # notebook task
  nb_task <- brickster::notebook_task(notebook_path = "MockNotebook")
  expect_s3_class(nb_task, c("NotebookTask", "JobTask"))
  expect_true(brickster::is.notebook_task(nb_task))
  expect_true(brickster::is.valid_task_type(nb_task))

  # spark jar task
  sj_task <- brickster::spark_jar_task(main_class_name = "MockClass")
  expect_s3_class(sj_task, c("SparkJarTask", "JobTask"))
  expect_true(brickster::is.spark_jar_task(sj_task))
  expect_true(brickster::is.valid_task_type(sj_task))

  # spark python task
  sp_task <- brickster::spark_python_task(python_file = "MockPythonScript")
  expect_s3_class(sp_task, c("SparkPythonTask", "JobTask"))
  expect_true(brickster::is.spark_python_task(sp_task))
  expect_true(brickster::is.valid_task_type(sp_task))

  # spark submit task
  ss_task <- brickster::spark_submit_task(parameters = list(a = "A", b = "B"))
  expect_s3_class(ss_task, c("SparkSubmitTask", "JobTask"))
  expect_true(brickster::is.spark_submit_task(ss_task))
  expect_true(brickster::is.valid_task_type(ss_task))

  # pipeline task
  pl_task <- brickster::pipeline_task(pipeline_id = "MockPipelineId")
  expect_s3_class(pl_task, c("PipelineTask", "JobTask"))
  expect_true(brickster::is.pipeline_task(pl_task))
  expect_true(brickster::is.valid_task_type(pl_task))

  # python wheel task
  pw_task <- brickster::python_wheel_task(package_name = "MockPythonWheel")
  expect_s3_class(pw_task, c("PythonWheelTask", "JobTask"))
  expect_true(brickster::is.python_wheel_task(pw_task))
  expect_true(brickster::is.valid_task_type(pw_task))

})

test_that("library object behaviour", {

  # jar
  jar <- brickster::lib_jar(jar = "MockJar.jar")
  expect_s3_class(jar, c("JarLibrary", "Library"))
  expect_true(brickster::is.lib_jar(jar))
  expect_true(brickster::is.library(jar))

  # egg
  egg <- brickster::lib_egg(egg = "s3://mock-bucket/MockEgg")
  expect_s3_class(egg, c("EggLibrary", "Library"))
  expect_true(brickster::is.lib_egg(egg))
  expect_true(brickster::is.library(egg))

  # wheel
  whl <- brickster::lib_whl(whl = "s3://mock-bucket/MockWheel")
  expect_s3_class(whl, c("WhlLibrary", "Library"))
  expect_true(brickster::is.lib_whl(whl))
  expect_true(brickster::is.library(whl))

  # PyPI
  pypi <- brickster::lib_pypi(package = "MockPackage")
  expect_s3_class(pypi, c("PyPiLibrary", "Library"))
  expect_true(brickster::is.lib_pypi(pypi))
  expect_true(brickster::is.library(pypi))

  # maven
  maven <- brickster::lib_maven(coordinates = "org.Mock.Package:0.0.1")
  expect_s3_class(maven, c("MavenLibrary", "Library"))
  expect_true(brickster::is.lib_maven(maven))
  expect_true(brickster::is.library(maven))

  # cran
  cran <- brickster::lib_cran(package = "brickster")
  expect_s3_class(cran, c("CranLibrary", "Library"))
  expect_true(brickster::is.lib_cran(cran))
  expect_true(brickster::is.library(cran))

  # libraries object
  libs <- brickster::libraries(jar, egg, whl, pypi, maven, cran)
  expect_s3_class(libs, c("Libraries", "list"))
  expect_true(brickster::is.libraries(libs))
  expect_error(brickster::libraries(123))
  expect_error(brickster::libraries("MockLibrary"))
  expect_error(brickster::libraries("MockLibrary", jar, cran))

})

test_that("access control object behaviour", {

  ## user
  # test all permissions are okay
  valid_permissions <- c("CAN_MANAGE", "CAN_MANAGE_RUN", "CAN_VIEW", "IS_OWNER")
  for (perm in valid_permissions) {
    expect_s3_class(
      cont_req_user <- brickster::access_control_req_user(
        user_name = "user@mock.com",
        permission_level = perm
      ),
      class = c("AccessControlRequestForUser", "list")
    )
    expect_true(brickster::is.access_control_req_user(cont_req_user))
  }

  # test invalid permissions raise errors
  invalid_permissions <- list(
    "can_manage", "mock_permission",
    123, 123L,
    list(), character(0)
  )
  for (perm in invalid_permissions) {
    expect_error(
      brickster::access_control_req_user(
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
      cont_req_grp <- brickster::access_control_req_group(
        group = "MockGroup",
        permission_level = perm
      ),
      class = c("AccessControlRequestForUser", "list")
    )
    expect_true(brickster::is.access_control_req_group(cont_req_grp))
  }

  # test invalid permissions raise errors
  invalid_permissions <- list(
    "can_manage", "mock_permission",
    123, 123L,
    list(), character(0)
  )
  for (perm in invalid_permissions) {
    expect_error(
      brickster::access_control_req_group(
        group = "MockGroup",
        permission_level = perm
      )
    )
  }

  # access control request
  group_perm <- brickster::access_control_req_group(
    group = "MockGroup",
    permission_level = "CAN_VIEW"
  )
  user_perm <- brickster::access_control_req_user(
    user_name = "user@mock.com",
    permission_level = "IS_OWNER"
  )
  expect_s3_class(
    brickster::access_control_request(group_perm),
    c("AccessControlRequest", "list")
  )
  expect_s3_class(
    brickster::access_control_request(user_perm),
    c("AccessControlRequest", "list")
  )
  expect_s3_class(
    brickster::access_control_request(group_perm, user_perm),
    c("AccessControlRequest", "list")
  )
  expect_length(
    brickster::access_control_request(group_perm, user_perm),
    2L
  )
  expect_true(
    is.access_control_request(
      brickster::access_control_request(group_perm, user_perm)
    )
  )

})


test_that("cron object behaviour", {

  # we do not check validity of CRON expression or timezone
  # these checks are made via API which provides appropriate response and error
  valid_status <- c("UNPAUSED", "PAUSED")
  for (status in valid_status) {
    expect_s3_class(
      cron <- brickster::cron_schedule(
        quartz_cron_expression = "* * * 5 *",
        timezone_id = "Etc/UTC",
        pause_status = status
      ),
      c("CronSchedule", "list")
    )
    expect_true(brickster::is.cron_schedule(cron))
  }

  invalid_status <- c("paused", "active", 123L, 123, character(0))
  for (status in invalid_status) {
    expect_error(
      brickster::cron_schedule(
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
      brickster::email_notifications(
        on_start = not_allowed_on,
        on_success = not_allowed_on,
        on_failure = not_allowed_on
      )
    )
  }

  for (input in not_allowed_alert) {
    expect_error(
      brickster::email_notifications(
        on_start = allowed,
        on_success = allowed,
        on_failure = allowed,
        no_alert_for_skipped_runs = input
      )
    )
  }

  # test that valid inputs don't error
  expect_s3_class(
    email_notif <- brickster::email_notifications(
      on_start = allowed,
      on_success = allowed,
      on_failure = allowed
    ),
    c("JobEmailNotifications", "list")
  )
  expect_true(brickster::is.email_notifications(email_notif))

  expect_s3_class(
    email_notif2 <- brickster::email_notifications(
      on_start = allowed,
      on_success = allowed,
      on_failure = allowed,
      no_alert_for_skipped_runs = FALSE
    ),
    c("JobEmailNotifications", "list")
  )
  expect_true(brickster::is.email_notifications(email_notif2))

})


test_that("cluster objects behaviour", {

  # cluster autoscale
  expect_s3_class(
    autoscale <- brickster::cluster_autoscale(min_workers = 2, max_workers = 4),
    c("AutoScale", "list")
  )
  expect_true(brickster::is.cluster_autoscale(autoscale))

  expect_error(brickster::cluster_autoscale(min_workers = 2, max_workers = 0))
  expect_error(brickster::cluster_autoscale(min_workers = 2, max_workers = 2))
  expect_error(brickster::cluster_autoscale(min_workers = -2, max_workers = 2))
  expect_error(brickster::cluster_autoscale(min_workers = 2))
  expect_error(brickster::cluster_autoscale(max_workers = 2))

  # dbfs storage
  expect_s3_class(
    dbfs <- brickster::dbfs_storage_info(destination = "/mock/storage/path"),
    c("DbfsStorageInfo", "list")
  )
  expect_true(brickster::is.dbfs_storage_info(dbfs))

  # file storage
  expect_s3_class(
    fs <- brickster::file_storage_info(destination = "/mock/storage/path"),
    c("DbfsStorageInfo", "list")
  )
  expect_true(brickster::is.file_storage_info(fs))

  # s3 storage info
  expect_s3_class(
    s3 <- brickster::s3_storage_info(
      destination = "s3://mock/bucket/path",
      region = "ap-southeast-2"
    ),
    c("S3StorageInfo", "list")
  )
  expect_true(brickster::is.s3_storage_info(s3))
  expect_error(
    brickster::s3_storage_info(
      destination = "s3://mock/bucket/path",
      region = "ap-southeast-2",
      encryption_type = "mock_encrypton"
    )
  )
  expect_length(
    brickster::s3_storage_info(
      destination = "s3://mock/bucket/path",
      region = "ap-southeast-2",
      encryption_type = c("sse-s3", "sse-kms")
    )$encryption_type,
    1
  )

  # cluster log conf
  expect_s3_class(
    clc_dbfs <- brickster::cluster_log_conf(dbfs = dbfs),
    c("ClusterLogConf", "list")
  )
  expect_true(brickster::is.cluster_log_conf(clc_dbfs))

  expect_s3_class(
    clc_s3 <- brickster::cluster_log_conf(s3 = s3),
    c("ClusterLogConf", "list")
  )
  expect_true(brickster::is.cluster_log_conf(clc_s3))

  expect_error(brickster::cluster_log_conf(dbfs = dbfs, s3 = s3))
  expect_error(brickster::cluster_log_conf(s3 = dbfs))
  expect_error(brickster::cluster_log_conf(dbfs = s3))
  expect_error(brickster::cluster_log_conf(dbfs = fs))
  expect_error(brickster::cluster_log_conf(s3 = fs))
  expect_error(brickster::cluster_log_conf())

  # docker image
  mock_image <- brickster::docker_image("mock_url", "mock_user", "mock_pass")
  expect_s3_class(mock_image, c("DockerImage", "list"))
  expect_true(brickster::is.docker_image(mock_image))
  expect_false(brickster::is.docker_image(list()))
  expect_error(brickster::docker_image())
  expect_error(brickster::docker_image(list()))

  # init script
  expect_s3_class(
    init <- brickster::init_script_info(s3, dbfs, fs),
    c("InitScriptInfo", "list")
  )
  expect_s3_class(
    init_script_info(),
    c("InitScriptInfo", "list")
  )
  expect_true(brickster::is.init_script_info(init))

  expect_error(brickster::init_script_info(1))
  expect_error(brickster::init_script_info("a"))
  expect_error(brickster::init_script_info(fs, 1))

  ## cloud attributes
  # gcp
  expect_s3_class(brickster::gcp_attributes(), c("GcpAttributes", "list"))
  expect_true(brickster::is.gcp_attributes(brickster::gcp_attributes()))

  # aws
  expect_s3_class(brickster::aws_attributes(), c("AwsAttributes", "list"))
  expect_true(brickster::is.aws_attributes(brickster::aws_attributes()))

  # azure
  expect_s3_class(brickster::azure_attributes(), c("AzureAttributes", "list"))
  expect_true(brickster::is.azure_attributes(brickster::azure_attributes()))
  expect_error(brickster::azure_attributes(first_on_demand = -1))
  expect_error(brickster::azure_attributes(first_on_demand = 0))

  # new cluster
  # TODO: add more checks, but should add more logic to `new_cluster()`
  cloud_attr_types <- list(
    brickster::aws_attributes(),
    brickster::gcp_attributes(),
    brickster::azure_attributes()
  )

  for (cloud in cloud_attr_types) {
    cluster <- brickster::new_cluster(
      num_workers = 1,
      spark_version = "mock_spark_version",
      node_type_id = "mock_node_type_id",
      driver_node_type_id = "mock_driver_node_type_id",
      cloud_attrs = cloud
    )
    expect_s3_class(cluster, c("NewCluster", "list"))
    expect_true(brickster::is.new_cluster(cluster))
  }

  expect_error(
    brickster::new_cluster(
      num_workers = 1,
      spark_version = "mock_spark_version",
      node_type_id = "mock_node_type_id",
      driver_node_type_id = "mock_driver_node_type_id",
      cloud_attrs = list()
    )
  )

})

test_that("git_source behaviour", {


  gs_git_tag <- brickster::git_source(
    git_url = "mockUrl",
    git_provider = "github",
    reference = "a",
    type = "tag"
  )

  gs_git_branch <- brickster::git_source(
    git_url = "mockUrl",
    git_provider = "github",
    reference = "a",
    type = "branch"
  )

  gs_git_commit <- brickster::git_source(
    git_url = "mockUrl",
    git_provider = "github",
    reference = "a",
    type = "commit"
  )

  expect_s3_class(gs_git_tag, c("GitSource", "list"))
  expect_s3_class(gs_git_branch, c("GitSource", "list"))
  expect_s3_class(gs_git_commit, c("GitSource", "list"))

  expect_true(brickster::is.git_source(gs_git_tag))
  expect_true(brickster::is.git_source(gs_git_branch))
  expect_true(brickster::is.git_source(gs_git_commit))

  expect_error(
    brickster::git_source(
      git_url = "mockUrl",
      git_provider = "fake",
      reference = "a",
      type = "commit"
    )
  )

  expect_error(
    brickster::git_source(
      git_provider = "fake",
      reference = "a",
      type = "commit"
    )
  )

  expect_error(
    brickster::git_source(
      git_url = "mockUrl",
      reference = "a",
      type = "commit"
    )
  )

  expect_error(brickster::git_source())

})
