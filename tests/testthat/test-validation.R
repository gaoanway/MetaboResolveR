test_that("validation requires at least one annotation identity column", {
  expect_error(
    MetaboResolveR:::validate_annotation_table(data.frame(qc_rsd = 10)),
    "must contain at least one annotation identity column"
  )
})

test_that("validation standardizes common input columns", {
  validated <- MetaboResolveR:::validate_annotation_table(
    data.frame(Metabolites = "Glucose", HMDB = "HMDB0000122", check.names = FALSE)
  )

  expect_true("metabolite_name" %in% names(validated))
  expect_true("hmdb_id" %in% names(validated))
  expect_identical(validated$normalized_name[[1]], "glucose")
})

test_that("validation accepts common identifier-only aliases", {
  validated <- MetaboResolveR:::validate_annotation_table(
    data.frame(
      HMID = "hmdb0000122",
      `PubChem CID` = "CID:1102",
      `ChEBI ID` = "CHEBI:16610",
      KEGG = "c00315",
      check.names = FALSE
    )
  )

  expect_identical(validated$hmdb_id[[1]], "HMDB0000122")
  expect_identical(validated$pubchem_cid[[1]], "1102")
  expect_identical(validated$chebi_id[[1]], "16610")
  expect_identical(validated$kegg_id[[1]], "C00315")
})

test_that("validation accepts real-case vendor-style column names", {
  validated <- MetaboResolveR:::validate_annotation_table(
    data.frame(
      Name = "Glucose",
      HMDB_ID = "HMDB0000122",
      KEGG_ID = "C00031",
      Lipidmaps_ID = "-",
      PubChemID = "5793",
      Formula = "C6H12O6",
      `m/z` = 181.0712,
      `RT (min)` = 0.82,
      IonMode = "P",
      Score = "0.92",
      check.names = FALSE
    )
  )

  expect_identical(validated$metabolite_name[[1]], "Glucose")
  expect_identical(validated$hmdb_id[[1]], "HMDB0000122")
  expect_identical(validated$kegg_id[[1]], "C00031")
  expect_identical(validated$pubchem_cid[[1]], "5793")
  expect_true(is.na(validated$lipidmaps_id[[1]]))
  expect_equal(validated$retention_time[[1]], 0.82)
  expect_equal(validated$ms2_score[[1]], 0.92)
})

test_that("placeholder identifiers do not count as structured IDs", {
  validated <- MetaboResolveR:::validate_annotation_table(
    data.frame(
      Name = "Unknown feature",
      HMDB_ID = "-",
      KEGG_ID = "-",
      Lipidmaps_ID = "-",
      PubChemID = "-",
      check.names = FALSE
    )
  )

  expect_true(all(is.na(validated[c("hmdb_id", "kegg_id", "lipidmaps_id", "pubchem_cid")])))
  expect_identical(MetaboResolveR:::score_annotation_evidence(validated), 0L)
})
