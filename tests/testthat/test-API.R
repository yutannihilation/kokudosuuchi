context("API")

result <-
  structure(
    list(
      identifier = c("W05", "W05"),
      title = c("\u6cb3\u5ddd",
                "\u6cb3\u5ddd"),
      field = c(
        "\u56fd\u571f\uff08\u6c34\u30fb\u571f\u5730\uff09",
        "\u56fd\u571f\uff08\u6c34\u30fb\u571f\u5730\uff09"
      ),
      year = c("2009", "2009"),
      areaType = c("3", "3"),
      areaCode = c("27", "28"),
      datum = c("1", "1"),
      zipFileUrl = c(
        "http://nlftp.mlit.go.jp/ksj/gml/data/W05/W05-09/W05-09_27_GML.zip",
        "http://nlftp.mlit.go.jp/ksj/gml/data/W05/W05-09/W05-09_28_GML.zip"
      ),
      zipFileSize = c("1.56MB", "6.85MB")
    ),
    .Names = c(
      "identifier",
      "title",
      "field",
      "year",
      "areaType",
      "areaCode",
      "datum",
      "zipFileUrl",
      "zipFileSize"
    ),
    row.names = c(NA, -2L),
    class = c("tbl_df", "tbl", "data.frame")
  )

test_that("multiplication works", {
  skip_on_cran()

  expect_equal(getKSJURL("W05", prefCode = c(27, 28)), result)
})
