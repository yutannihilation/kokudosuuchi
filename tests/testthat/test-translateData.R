context("translateData")

test_that("translateKSJData_one() works for duplicated columns", {
  d <- data.frame(A10_001 = 1, A10_002 = 2, A10_003 = 3, A10_004 = 4)

  expect_equal(colnames(translateKSJData_one(d)),
               c("\u90fd\u9053\u5e9c\u770c\u30b3\u30fc\u30c9",
                 "\u632f\u8208\u5c40\u30b3\u30fc\u30c9",
                 "\u81ea\u7136\u516c\u5712\u533a\u5206\u30b3\u30fc\u30c9",
                 "\u81ea\u7136\u516c\u5712\u5730\u57df\u533a\u5206\u30b3\u30fc\u30c9"))

  expect_equal(colnames(translateKSJData_one(d[, 1:3])),
               c("\u90fd\u9053\u5e9c\u770c\u30b3\u30fc\u30c9",
                 "\u652f\u5e81\u533a\u5206\u30b3\u30fc\u30c9",
                 "\u81ea\u7136\u516c\u5712\u5730\u57df\u533a\u5206\u30b3\u30fc\u30c9"))

  d2 <- dplyr::rename(d, geometry = A10_004)
  expect_equal(colnames(translateKSJData_one(d2)),
               c("\u90fd\u9053\u5e9c\u770c\u30b3\u30fc\u30c9",
                 "\u652f\u5e81\u533a\u5206\u30b3\u30fc\u30c9",
                 "\u81ea\u7136\u516c\u5712\u5730\u57df\u533a\u5206\u30b3\u30fc\u30c9",
                 "geometry"))
})

test_that("translateKSJData() works for both a sf object and a list of sf objects", {
  sf_obj <- sf::st_sf(A10_001 = 1, A10_002 = 2, A10_003 = 3, A10_004 = 4, geometry = sf::st_sfc(sf::st_point(c(1,1))))
  sf_list <- list(a = sf_obj)

  colnames_expected <- c("\u90fd\u9053\u5e9c\u770c\u30b3\u30fc\u30c9",
                         "\u632f\u8208\u5c40\u30b3\u30fc\u30c9",
                         "\u81ea\u7136\u516c\u5712\u533a\u5206\u30b3\u30fc\u30c9",
                         "\u81ea\u7136\u516c\u5712\u5730\u57df\u533a\u5206\u30b3\u30fc\u30c9",
                         "geometry")

  expect_equal(colnames(translateKSJData(sf_obj)), colnames_expected)
  expect_equal(colnames(translateKSJData(sf_list)[[1]]), colnames_expected)
  expect_s3_class(translateKSJData(sf_list)[[1]], "sf")
})


test_that("translateKSJData() works for clnames with years", {
  sf_obj <- sf::st_sf(
    A22_000001 = 1,
    A22_000002 = 2,
    A22_000003 = 3,
    A22_012013 = 4,
    A22_012012 = 5,
    geometry   = sf::st_sfc(sf::st_point(1:2))
  )

  colnames_expected <- c("\u89b3\u6e2c\u70b9\u540d",
                         "\u89b3\u6e2c\u70b9\u306e\u6240\u5728\u5730",
                         "\u89b3\u6e2c\u70b9\u306e\u7ba1\u7406\u8005",
                         "\u5404\u5e74\u5ea6\u5225\u6700\u6df1\u7a4d\u96ea2013\u5e74\u5ea6",
                         "\u5404\u5e74\u5ea6\u5225\u6700\u6df1\u7a4d\u96ea2012\u5e74\u5ea6",
                         "geometry")

  expect_equal(colnames(translateKSJData(sf_obj)), colnames_expected)
})
