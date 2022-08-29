http_mock_status <- function(status) {
  expr <- substitute(
    expression(
      function(x) {
        httr2::response(status_code = status)
      }
    ), list(status = status))
  eval(expr, envir = NULL)
}

a <- http_mock_status(200)
a

httr2::with_mock(my_mock, {
  db_repo_get(repo_id = 1, perform_request = FALSE) %>%
    httr2::req_perform()
})


test_that("repos api behaviour", {

  expect_error()
  expect_s3_class()
  expect_



})
