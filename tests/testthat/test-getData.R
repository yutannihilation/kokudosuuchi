context("getData")

test_that("getKSJData works", {
  d <- getKSJData("http://nlftp.mlit.go.jp/ksj/gml/data/L01/L01-01/L01-01_36_GML.zip")

  expect_equal(names(d), "L01-01_36-g_LandPrice")
  expect_equal(nrow(d$`L01-01_36-g_LandPrice`), 162)
  expect_s3_class(d$`L01-01_36-g_LandPrice`, "sf")
})

test_that("getKSJData with UTF-8 layers works", {
  d <- getKSJData("http://nlftp.mlit.go.jp/ksj/gml/data/P12/P12-14/P12-14_06_GML.zip")

  expect_equal(length(d), 3)
  purrr::walk(d, expect_s3_class, class = "sf")
  expect_equal(unname(purrr::map_int(d, nrow)), c(10L, 1L, 2L))
  expect_equal(names(d), c("P12a-14_06", "P12b-14_06", "P12c-14_06"))
})

test_that("getKSJData with UTF-8 layers with cached one works", {
  expect_message({d <- getKSJData("http://nlftp.mlit.go.jp/ksj/gml/data/P12/P12-14/P12-14_06_GML.zip")},
                 "Using cached data.")

  expect_equal(length(d), 3)
  purrr::walk(d, expect_s3_class, class = "sf")
  expect_equal(unname(purrr::map_int(d, nrow)), c(10L, 1L, 2L))
  expect_equal(names(d), c("P12a-14_06", "P12b-14_06", "P12c-14_06"))
})


test_that("getKSJData randomly works", {
  skip_on_travis()
  skip_on_cran()

  ksj_urls <- getKSJURL(identifier = sample(c("A11", "A15", "A16", "A17", "A19", "A19s", "A24", "A30a5",
                                              "A35b", "A35c", "C23", "G02", "G04-a", "G04-c", "G04-d", "L01",
                                              "L02", "L03-a", "L03-b-u", "L05", "N04", "N10", "N11", "P03",
                                              "P04", "P05", "P07", "P12", "P13", "P14", "P15", "P16", "P19",
                                              "P20", "P22", "P23", "P26", "P27", "P28", "P29", "P30", "P31",
                                              "P32", "P33", "P34", "S10b"), 1))
  ksj_urls_lite <- dplyr::filter(ksj_urls, readr::parse_number(zipFileSize) < 0.1)
  url <- sample(ksj_urls_lite$zipFileUrl, 1)
  cat(url)
  d <- getKSJData(url)
  purrr::walk(d, expect_s3_class, class = "sf")
})
