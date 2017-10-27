context("getData")

cache_dir <- "../../cached_zip"
if (!file.exists(cache_dir)) cache_dir <- tempfile()

test_that("getKSJData works", {
  skip_on_cran()

  d <- getKSJData("http://nlftp.mlit.go.jp/ksj/gml/data/L01/L01-01/L01-01_36_GML.zip",
                  cache_dir = cache_dir)

  expect_equal(names(d), "L01-01_36-g_LandPrice")
  expect_equal(nrow(d$`L01-01_36-g_LandPrice`), 162)
  expect_s3_class(d$`L01-01_36-g_LandPrice`, "sf")
})

verify_p12_14_06_gml <- function(d) {
  expect_equal(length(d), 3)
  purrr::walk(d, expect_s3_class, class = "sf")
  expect_equal(sort(unname(purrr::map_int(d, nrow))),
               sort(c(10L, 1L, 2L)))
  expect_equal(sort(names(d)),
               sort(c("P12a-14_06", "P12b-14_06", "P12c-14_06")))
}

test_that("getKSJData with UTF-8 layers works", {
  skip_on_cran()

  d <- getKSJData("http://nlftp.mlit.go.jp/ksj/gml/data/P12/P12-14/P12-14_06_GML.zip",
                  cache_dir = cache_dir)

  verify_p12_14_06_gml(d)
})

test_that("getKSJData with UTF-8 layers with cached one works", {
  skip_on_cran()

  expect_message({d <- getKSJData("http://nlftp.mlit.go.jp/ksj/gml/data/P12/P12-14/P12-14_06_GML.zip",
                                  cache_dir = cache_dir)},
                 "Using the cached zip file")

  verify_p12_14_06_gml(d)
})

zip_url <- "http://nlftp.mlit.go.jp/ksj/gml/data/P12/P12-14/P12-14_06_GML.zip"
zip_file <- file.path(cache_dir, basename(zip_url))

test_that("getKSJData with UTF-8 layers with a zip file works", {
  skip_on_cran()

  curl::curl_download(zip_url, destfile = zip_file)

  d <- getKSJData(zip_file)

  verify_p12_14_06_gml(d)
})

data_dir <- tempfile()

test_that("getKSJData with UTF-8 layers with a directory works", {
  skip_on_cran()

  utils::unzip(zip_file, exdir = data_dir)
  d <- getKSJData(data_dir)

  verify_p12_14_06_gml(d)
})

data_dir2 <- tempfile()

test_that("getKSJData with UTF-8 layers with a nested directory works", {
  skip_on_cran()

  dir.create(data_dir2)
  file.rename(data_dir, file.path(data_dir2, "nested"))
  d <- getKSJData(data_dir2)

  verify_p12_14_06_gml(d)
})


test_that("getKSJData randomly works", {
  if (identical(Sys.getenv("CIRCLECI"), "true")) skip("On CircleCI")
  skip_on_appveyor()
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
  d <- getKSJData(url, cache_dir = cache_dir)
  purrr::walk(d, expect_s3_class, class = "sf")
})
