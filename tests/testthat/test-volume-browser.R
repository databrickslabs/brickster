test_that("Volume browser", {

  withr::local_envvar(c(
    "DATABRICKS_HOST" = "http://mock_host",
    "DATABRICKS_TOKEN" = "mock_token"
  ))

  expect_identical(
    fullpath_to_pathcomponents("/Volumes"),
    list(catalog=NULL, schema=NULL, volume=NULL, path=NULL)
  )

  expect_identical(
    fullpath_to_pathcomponents("/Volumes/"),
    list(catalog=NULL, schema=NULL, volume=NULL, path=NULL)
  )

  expect_identical(
    fullpath_to_pathcomponents("/Volumes/catalog"),
    list(catalog="catalog", schema=NULL, volume=NULL, path=NULL)
  )

  expect_identical(
    fullpath_to_pathcomponents("/Volumes/catalog/"),
    list(catalog="catalog", schema=NULL, volume=NULL, path=NULL)
  )

  expect_identical(
    fullpath_to_pathcomponents("/Volumes/catalog/schema"),
    list(catalog="catalog", schema="schema", volume=NULL, path=NULL)
  )

  expect_identical(
    fullpath_to_pathcomponents("/Volumes/catalog/schema/"),
    list(catalog="catalog", schema="schema", volume=NULL, path=NULL)
  )

  expect_identical(
    fullpath_to_pathcomponents("/Volumes/catalog/schema/volume"),
    list(catalog="catalog", schema="schema", volume="volume", path=NULL)
  )

  expect_identical(
    fullpath_to_pathcomponents("/Volumes/catalog/schema/volume/"),
    list(catalog="catalog", schema="schema", volume="volume", path=NULL)
  )

  expect_identical(
    fullpath_to_pathcomponents("/Volumes/catalog/schema/volume/path/to/something"),
    list(catalog="catalog", schema="schema", volume="volume", path="path/to/something")
  )

  expect_identical(
    fullpath_to_pathcomponents("/Volumes/catalog/schema/volume/path/to/something/"),
    list(catalog="catalog", schema="schema", volume="volume", path="path/to/something/")
  )

  expect_identical(
    create_databricks_url_for_path(
      full_path = "/Volumes/catalog/schema/volume/path/to/something/",
      host = "mock_host",
      ws_id = "mock_ws_id"
    ), {
      pathenc <- utils::URLencode('/Volumes/catalog/schema/volume/path/to/something/', reserved=TRUE)
      glue::glue("https://mock_host/explore/data/volumes/catalog/schema/volume?o=mock_ws_id&volumePath={pathenc}")
    }
  )

  expect_identical(
    create_databricks_url_for_path(
      full_path = "/Volumes/catalog/schema/",
      host = "mock_host",
      ws_id = "mock_ws_id"
    ), {
      glue::glue("https://mock_host/explore/data/catalog/schema?o=mock_ws_id")
    }
  )

  key <- openssl::aes_keygen(length=32)
  expect_identical(
    decrypt_credentials(
      encrypt_credentials(
        host = db_host(), token = db_token(), key=key
      ),
      key
    ),
    list(host = db_host(), token = db_token())
  )

  expect_identical(length(get_random_port()), 1L)
  expect_true(inherits(get_random_port(), "integer"))

  expect_true(
    startsWith(
      build_volume_browser_url(path="/Volumes", port=5000, key = key),
      "http://localhost:5000?path=%2FVolumes&credentials="
    )
  )

  expect_true({
    start_volume_browser_app()
    is_alive <- vol_browser_singleton$app$is_alive()
    stop_volume_browser_app()
    is_alive
  })

})
