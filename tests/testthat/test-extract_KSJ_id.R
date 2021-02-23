test_that("extract_KSJ_id() works", {
  expect_equal(extract_KSJ_id("A03-03_SYUTO-tky_GML"), "A03")
  expect_equal(extract_KSJ_id("S05-a-10_KINKI_GML"), "S05-a")
  expect_equal(extract_KSJ_id("A30a5-11_5338-jgd_GML"), "A30a5")
  expect_equal(extract_KSJ_id("L03-b-c-16_5440_GML"), "L03-b-c")
  expect_equal(extract_KSJ_id("L03-b-16_3623-tky_GML"), "L03-b")

  # A19s-a is a variant of A19s
  expect_equal(extract_KSJ_id("A19s-a-10_28_GML"), "A19s")

  expect_equal(extract_KSJ_id("KS-META-A16-15_04"), "A16")
  expect_equal(extract_KSJ_id("KS-META-A18s_a_22_02"), "A18s-a")
  expect_equal(extract_KSJ_id("KS-META-A22-m-14_34"), "A22-m")
})
