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
