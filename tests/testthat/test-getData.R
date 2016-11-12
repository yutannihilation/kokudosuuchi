context("getData")

test_that("getKSJData works", {
  d <- getKSJData("http://nlftp.mlit.go.jp/ksj/gml/data/L01/L01-01/L01-01_36_GML.zip")

  expect_equal(names(d), "L01-01_36-g_LandPrice")
  expect_equal(nrow(d$`L01-01_36-g_LandPrice`), 162)
  expect_true(inherits(d$`L01-01_36-g_LandPrice`, "SpatialPointsDataFrame"))
  expect_true(inherits(d$`L01-01_36-g_LandPrice`@data, "data.frame"))
})


test_that("getKSJData randomly works", {
  if (!identical(Sys.getenv("TRAVIS"), "true")) {
    skip("RUN only on Travis")
  }

  ksj_summary <- getKSJSummary()
  ksj_urls <- getKSJURL(identifier = sample(ksj_summary$identifier, 1))
  with_mock(
    warn_no_corresp_names = function(...) TRUE,
    d <- getKSJData(sample(ksj_urls$zipFileUrl, 1))
  )

  expect_true(all(purrr::map_lgl(d, ~ class(.) %in% c("SpatialPointsDataFrame",
                                                      "SpatialLinesDataFrame",
                                                      "SpatialPolygonsDataFrame"))))
  expect_true(class(d[[1]]@data), "data.frame")
})
