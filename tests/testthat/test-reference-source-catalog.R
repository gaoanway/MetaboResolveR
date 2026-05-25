test_that("reference source catalog exists with required provenance columns", {
  catalog <- load_reference_source_catalog()

  expect_true(nrow(catalog) >= 8)
  expect_true(all(c(
    "source_id",
    "source_kind",
    "short_name",
    "title_or_resource",
    "resource_scope",
    "evidence_role",
    "primary_url",
    "citation_text",
    "update_strategy"
  ) %in% names(catalog)))

  expect_true("plasma_benchmark_2025" %in% catalog$source_id)
  expect_true("hmdb_main" %in% catalog$source_id)
  expect_true("blood_exposome" %in% catalog$source_id)
})

test_that("known SRM1950 source-name corruptions are corrected", {
  ref <- load_plasma_metabolite_evidence_reference()

  muricholic <- ref[ref$hmdb_id == "HMDB0000506" & ref$nist_srm1950 == "TRUE", ]
  methyl_cholic <- ref[ref$hmdb_id == "HMDB0244296" & ref$nist_srm1950 == "TRUE", ]

  expect_true(any(muricholic$normalized_name == "alpha-muricholic acid"))
  expect_false(any(grepl("λ", muricholic$normalized_name)))

  expect_true(any(methyl_cholic$normalized_name == "7-methyl-cholic acid"))
  expect_false(any(grepl("[Шш]", methyl_cholic$metabolite_name)))
})
