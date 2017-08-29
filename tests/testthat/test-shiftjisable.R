context("Shift_JIS-able")

test_that("is_non_utf8_character() works as expected", {
  # run only on local Windows
  skip_if_not(l10n_info()$codepage == 932L)

  x_utf8 <- "\u56fd\u571f\u6570\u5024\u60c5\u5831"
  x_cp932 <- iconv(x_utf8, from = "UTF-8", to = "CP932")

  expect_false(is_non_utf8_character(x_utf8))
  expect_true(is_non_utf8_character(x_cp932))
})
