test_that("exogenous flagging separates dietary and contaminant-like rows", {
  flagged <- flag_exogenous_compounds(
    data.frame(
      metabolite_name = c("Caffeine", "Bisphenol A", "Glucose"),
      sample_blank_ratio = c(20, 1.5, 15),
      stringsAsFactors = FALSE
    )
  )

  expect_true(flagged$exogenous_flag[[1]])
  expect_identical(flagged$exogenous_category[[1]], "dietary")
  expect_true(flagged$contaminant_flag[[2]])
  expect_false(flagged$exogenous_flag[[3]])
})
