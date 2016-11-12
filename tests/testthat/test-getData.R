context("getData")

test_that("getKSJData works", {
  d <- getKSJData("http://nlftp.mlit.go.jp/ksj/gml/data/W05/W05-07/W05-07_03_GML.zip")

  expect_equal(names(d), c("W05-07_03-g_RiverNode", "W05-07_03-g_Stream"))
  expect_equal(nrow(d$`W05-07_03-g_RiverNode`), 7534)
  expect_equal(nrow(d$`W05-07_03-g_Stream`), 7597)
})


test_that("getKSJData randomly works", {
  if (!identical(Sys.getenv("TRAVIS"), "true")) {
    skip("RUN only on Travis")
  }

  ksj_summary <- getKSJSummary()
  ksj_urls <- getKSJURL(identifier = sample(ksj_summary$identifier, 1))
  d <- getKSJData(sample(ksj_urls$zipFileUrl, 1))

  expect_true(all(purrr::map_lgl(d, ~ class(.) %in% c("SpatialPointsDataFrame",
                                                      "SpatialLinesDataFrame",
                                                      "SpatialPolygonsDataFrame"))))
})
