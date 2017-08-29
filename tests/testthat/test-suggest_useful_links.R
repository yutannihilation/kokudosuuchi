context("suggest useful links")

test_that("suggest_useful_links() works", {
  expect_message(suggest_useful_links("L01"),
                 "Details about this data can be found at http://nlftp.mlit.go.jp/ksj/gml/datalist/KsjTmplt-L01-v2_3.html")
})

test_that("suggest_useful_links() with invalid identifier works", {
  expect_silent(suggest_useful_links("L99"))
})
