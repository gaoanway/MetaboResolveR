test_that("plasma evidence favors known human plasma metabolites", {
  scored <- score_plasma_evidence(
    data.frame(
      metabolite_name = c("Glucose", "Mystery"),
      hmdb_id = c("HMDB0000122", NA_character_),
      stringsAsFactors = FALSE
    )
  )

  expect_gt(scored$plasma_evidence_score[[1]], scored$plasma_evidence_score[[2]])
  expect_match(scored$plasma_evidence_sources[[1]], "Plasma Benchmark")
})

test_that("HMDB matches prefer strongest duplicate evidence row", {
  scored <- score_plasma_evidence(
    data.frame(
      metabolite_name = "Glucose",
      hmdb_id = "HMDB0000122",
      stringsAsFactors = FALSE
    )
  )

  expect_match(scored$plasma_evidence_sources[[1]], "Ghosh 2024 core plasma")
  expect_true(scored$ghosh_2024_core_50pct_hit[[1]])
})

test_that("identifier-only rows can be scored and named from the reference", {
  scored <- score_plasma_evidence(
    data.frame(
      hmdb_id = c("HMDB0000122", NA, NA),
      pubchem_cid = c(NA, "1102", NA),
      chebi_id = c(NA, NA, "15903"),
      stringsAsFactors = FALSE
    )
  )

  expect_gt(scored$plasma_evidence_score[[1]], 0)
  expect_equal(scored$matched_reference_key[[1]], "hmdb_id")
  expect_match(scored$reference_metabolite_name[[1]], "glucose", ignore.case = TRUE)
  expect_gt(scored$plasma_evidence_score[[2]], 0)
  expect_equal(scored$matched_reference_key[[2]], "pubchem_cid")
  expect_match(scored$reference_metabolite_name[[2]], "spermidine", ignore.case = TRUE)
  expect_gt(scored$plasma_evidence_score[[3]], 0)
  expect_equal(scored$matched_reference_key[[3]], "chebi_id")
  expect_match(scored$reference_metabolite_name[[3]], "glucose", ignore.case = TRUE)
})
