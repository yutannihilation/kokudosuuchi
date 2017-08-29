context("is_file")

test_that("is_file() and is_dir() stops when the file does not exist. (This may be false-positive for Windows)", {
  x <- tempfile()
  expect_error(is_file(x))
  expect_error(is_dir(x))
})

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
