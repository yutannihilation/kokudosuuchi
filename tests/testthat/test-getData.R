context("getData")

test_that("getKSJData works", {
  d <- getKSJData("http://nlftp.mlit.go.jp/ksj/gml/data/L01/L01-01/L01-01_36_GML.zip")

  expect_equal(names(d), "L01-01_36-g_LandPrice")
  expect_equal(nrow(d$`L01-01_36-g_LandPrice`), 162)
  expect_true(inherits(d$`L01-01_36-g_LandPrice`, "SpatialPointsDataFrame"))
  expect_true(inherits(d$`L01-01_36-g_LandPrice`@data, "data.frame"))
})
