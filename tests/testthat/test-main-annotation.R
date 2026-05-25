test_that("main annotation returns interpretable plasma-oriented classes", {
  input <- data.frame(
    metabolite_name = c(
      "Glucose",
      "Carnitine",
      "Caffeine",
      "Bisphenol A",
      "PC(16:0/18:2)",
      "Unknown feature"
    ),
    hmdb_id = c(
      "HMDB0000122",
      "HMDB0000062",
      "HMDB0001847",
      NA,
      NA,
      NA
    ),
    formula = c(
      "C6H12O6",
      "C7H15NO3",
      "C8H10N4O2",
      "C15H16O2",
      "C42H82NO8P",
      NA
    ),
    adduct = c("[M+H]+", "[M+H]+", "[M+H]+", "[M-H]-", "[M+H]+", NA),
    mz = c(181.0712, 162.1125, 195.0877, 227.1072, 758.5696, NA),
    retention_time = c(0.82, 1.43, 2.91, 6.44, 7.18, 4.20),
    polarity = c(
      "positive",
      "positive",
      "positive",
      "negative",
      "positive",
      "positive"
    ),
    ms2_score = c(0.95, 0.91, 0.88, 0.72, 0.81, 0.20),
    qc_rsd = c(8, 11, 13, 21, 16, 41),
    sample_blank_ratio = c(18, 14, 22, 1.5, 11, 2.1),
    missing_rate = c(0.02, 0.05, 0.08, 0.14, 0.09, 0.62),
    stringsAsFactors = FALSE
  )

  annotated <- annotate_plasma_metabolites(input)

  expect_true(all(c(
    "plasma_evidence_score",
    "annotation_evidence_score",
    "technical_quality_score",
    "final_confidence_score",
    "final_annotation_class"
  ) %in% names(annotated)))

  expect_identical(
    annotated$final_annotation_class[annotated$metabolite_name == "Glucose"],
    "core_plasma_metabolite"
  )
  expect_identical(
    annotated$final_annotation_class[annotated$metabolite_name == "Caffeine"],
    "exposure_related_metabolite"
  )
  expect_identical(
    annotated$final_annotation_class[annotated$metabolite_name == "Bisphenol A"],
    "remove_contaminant"
  )
  expect_identical(
    annotated$final_annotation_class[annotated$metabolite_name == "PC(16:0/18:2)"],
    "lipid_class_only"
  )
})

test_that("main annotation can classify identifier-only rows", {
  annotated <- annotate_plasma_metabolites(
    data.frame(
      hmid = "HMDB0000122",
      ms2_score = 0.90,
      qc_rsd = 10,
      sample_blank_ratio = 10,
      missing_rate = 0.10,
      stringsAsFactors = FALSE
    )
  )

  expect_identical(annotated$matched_reference_key[[1]], "hmdb_id")
  expect_match(annotated$reference_metabolite_name[[1]], "glucose", ignore.case = TRUE)
  expect_identical(annotated$final_annotation_class[[1]], "core_plasma_metabolite")
})
