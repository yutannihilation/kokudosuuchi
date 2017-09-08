context("is_file")

test_that("is_file() and is_dir() works fine with a file", {
  x <- tempfile()
  file.create(x)

  expect_true(is_file(x))
  expect_false(is_dir(x))
})

test_that("is_file() and is_dir() works fine with a directory", {
  x <- tempfile()
  dir.create(x)

  expect_false(is_file(x))
  expect_true(is_dir(x))
})

test_that("is_file() and is_dir() works fine with a directory with / at its tail", {
  x <- tempfile()
  x <- glue::glue("{x}/")
  dir.create(x)

  expect_false(is_file(x))
  expect_true(is_dir(x))
})
