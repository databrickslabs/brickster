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

})
