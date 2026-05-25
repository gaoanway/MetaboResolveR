test_that("lipid normalization collapses molecular species to sum composition", {
  lipids <- normalize_lipid_annotation(c("PC(16:0/18:2)", "Glucose"))

  expect_identical(lipids$normalized_name[[1]], "PC(34:2)")
  expect_identical(lipids$lipid_class[[1]], "PC")
  expect_identical(lipids$lipid_annotation_level[[1]], "sum_composition")
  expect_false(lipids$is_lipid[[2]])
})
