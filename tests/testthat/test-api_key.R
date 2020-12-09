testthat::test_that("Check Default URL", {
  res = httr::HEAD(mario_api_url())
  testthat::expect_equal(httr::status_code(res), 404)
})
