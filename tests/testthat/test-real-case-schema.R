test_that("real-case schema can be annotated without an explicit column map", {
  input <- data.frame(
    Compound_ID = c("Com_001_all", "Com_002_all"),
    Name = c("Glucose", "Unknown feature"),
    ChineseName = c("葡萄糖", "未知峰"),
    IonMode = c("P", "N"),
    Formula = c("C6H12O6", NA),
    MolecularWeight = c(180.0634, NA),
    `m/z` = c(181.0712, 300.2),
    MassError = c(1.2, 5.1),
    Adduct = c("[M+H]+", "[M-H]-"),
    `RT (min)` = c(0.82, 4.2),
    Score = c("0.95", "0.50"),
    Level = c(2, 3),
    ClassI = c("Organic oxygen compounds", "-"),
    HMDB_ID = c("HMDB0000122", "-"),
    KEGG_ID = c("C00031", "-"),
    Lipidmaps_ID = c("-", "-"),
    PubChemID = c("5793", "-"),
    check.names = FALSE
  )

  annotated <- annotate_plasma_metabolites(input)

  expect_equal(nrow(annotated), 2)
  expect_identical(annotated$matched_reference_key[[1]], "hmdb_id")
  expect_true(is.na(annotated$hmdb_id[[2]]))
  expect_true(is.na(annotated$pubchem_cid[[2]]))
  expect_true("final_annotation_class" %in% names(annotated))
})

test_that("public real-case schema fixture remains readable", {
  fixture <- system.file("extdata", "example_real_case_schema.csv", package = "MetaboResolveR")
  expect_true(file.exists(fixture))

  input <- utils::read.csv(fixture, stringsAsFactors = FALSE, check.names = FALSE)
  annotated <- annotate_plasma_metabolites(input)

  expect_equal(nrow(annotated), 4)
  expect_true(all(c("metabolite_name", "matched_reference_key", "final_annotation_class") %in% names(annotated)))
})
