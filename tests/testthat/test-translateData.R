# NOTE: To enable this test, I need to download zip files to "tests/testthat/zip" manually...

test_that("readKSJData() works", {
  skip_on_ci()
  skip_on_cran()
  skip_if_not(dir.exists("zip"))

  d <- readKSJData("zip/P11-10_36_GML.zip")
  expect_snapshot(translateKSJData(d))
  expect_snapshot(translateKSJData(d, translate_colnames = FALSE))
  expect_snapshot(translateKSJData(d, translate_codelist = FALSE))

  d_A03 <- readKSJData("zip/A03-03_SYUTO-tky_GML.zip")
  expect_snapshot(translateKSJData(d_A03))

  d_A22_m <- readKSJData("zip/A22-m-14_34_GML.zip")
  expect_snapshot(translateKSJData(d_A22_m))

  d_A37 <- readKSJData("zip/A37-15_45_GML.zip")
  expect_snapshot(translateKSJData(d_A37))

  d_C02 <- readKSJData("zip/C02-14_GML.zip")
  expect_snapshot(translateKSJData(d_C02))

  d_L01 <- readKSJData("zip/L01-20_30_GML.zip")
  expect_snapshot(translateKSJData(d_L01))

  d_N04 <- readKSJData("zip/N04-04_4934-jgd_GML.zip")
  expect_snapshot(translateKSJData(d_N04))

  d_P17 <- readKSJData("zip/P17-12_29_GML.zip")
  expect_snapshot(translateKSJData(d_P17))

  d_P21 <- readKSJData("zip/P21-12_15_GML.zip")
  expect_snapshot(translateKSJData(d_P21))
})
