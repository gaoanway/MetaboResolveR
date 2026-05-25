score_annotation_evidence <- function(data) {
  score <- integer(nrow(data))
  has_structured_id <- rep(FALSE, nrow(data))

  id_fields <- c("hmdb_id", "kegg_id", "pubchem_cid", "chebi_id", "lipidmaps_id")
  for (field in id_fields) {
    if (field %in% names(data)) {
      value <- data[[field]]
      has_structured_id <- has_structured_id | (!is.na(value) & trimws(as.character(value)) != "")
    }
  }

  score <- score + ifelse(has_structured_id, 1L, 0L)
  if ("formula" %in% names(data)) {
    score <- score + ifelse(!is.na(data$formula) & trimws(as.character(data$formula)) != "", 1L, 0L)
  }
  if ("ms2_score" %in% names(data)) {
    score <- score + ifelse(!is.na(data$ms2_score) & data$ms2_score >= 0.70, 1L, 0L)
    score <- score + ifelse(!is.na(data$ms2_score) & data$ms2_score >= 0.85, 1L, 0L)
  }
  score
}

score_technical_quality <- function(data) {
  score <- integer(nrow(data))
  if ("qc_rsd" %in% names(data)) {
    score <- score + ifelse(!is.na(data$qc_rsd) & data$qc_rsd <= 30, 1L, 0L)
  }
  if ("sample_blank_ratio" %in% names(data)) {
    score <- score + ifelse(!is.na(data$sample_blank_ratio) & data$sample_blank_ratio >= 5, 1L, 0L)
  }
  if ("missing_rate" %in% names(data)) {
    score <- score + ifelse(!is.na(data$missing_rate) & data$missing_rate <= 0.50, 1L, 0L)
  }
  score
}

reference_match_rank <- function(reference) {
  score <- integer(nrow(reference))
  if ("plasma_benchmark" %in% names(reference)) {
    score <- score + ifelse(normalize_logical_flag(reference$plasma_benchmark), 100L, 0L)
  }
  if ("nist_srm1950" %in% names(reference)) {
    score <- score + ifelse(normalize_logical_flag(reference$nist_srm1950), 100L, 0L)
  }
  if ("ghosh_2024_core_50pct" %in% names(reference)) {
    score <- score + ifelse(normalize_logical_flag(reference$ghosh_2024_core_50pct), 100L, 0L)
  }
  if ("ghosh_2024_all5_cohorts" %in% names(reference)) {
    score <- score + ifelse(normalize_logical_flag(reference$ghosh_2024_all5_cohorts), 50L, 0L)
  }
  if ("ghosh_2024_plasma" %in% names(reference)) {
    score <- score + ifelse(normalize_logical_flag(reference$ghosh_2024_plasma), 20L, 0L)
  }
  if ("hmdb_biofluid" %in% names(reference)) {
    score <- score + ifelse(normalize_logical_flag(reference$hmdb_biofluid), 20L, 0L)
  }
  if ("serum_evidence" %in% names(reference)) {
    score <- score + ifelse(normalize_logical_flag(reference$serum_evidence), 10L, 0L)
  }
  if ("srm1950_db" %in% names(reference)) {
    score <- score + ifelse(normalize_logical_flag(reference$srm1950_db), 100L, 0L)
  }
  if ("source_count" %in% names(reference)) {
    suppressWarnings(score <- score + as.integer(as.numeric(reference$source_count)))
  }
  score
}

best_reference_indices <- function(input_values, reference_values, rank) {
  idx <- rep(NA_integer_, length(input_values))
  has_value <- !is.na(input_values) & trimws(as.character(input_values)) != ""
  values <- unique(input_values[has_value])
  best <- stats::setNames(rep(NA_integer_, length(values)), values)
  for (value in values) {
    candidates <- which(reference_values == value)
    if (length(candidates) > 0) {
      best[[value]] <- candidates[[which.max(rank[candidates])]]
    }
  }
  idx[has_value] <- unname(best[input_values[has_value]])
  idx
}

join_plasma_reference <- function(data, reference) {
  rank <- reference_match_rank(reference)
  idx_name <- match(data$normalized_name, reference$normalized_name)
  match_key <- rep("", nrow(data))
  idx <- rep(NA_integer_, nrow(data))

  if ("hmdb_id" %in% names(data)) {
    idx_hmdb <- best_reference_indices(data$hmdb_id, reference$hmdb_id, rank)
    take <- is.na(idx) & !is.na(idx_hmdb)
    idx[take] <- idx_hmdb[take]
    match_key[take] <- "hmdb_id"
  }
  if ("pubchem_cid" %in% names(data) && "pubchem_cid" %in% names(reference)) {
    idx_pubchem <- best_reference_indices(data$pubchem_cid, reference$pubchem_cid, rank)
    take <- is.na(idx) & !is.na(idx_pubchem)
    idx[take] <- idx_pubchem[take]
    match_key[take] <- "pubchem_cid"
  }
  if ("chebi_id" %in% names(data) && "chebi_id" %in% names(reference)) {
    idx_chebi <- best_reference_indices(data$chebi_id, reference$chebi_id, rank)
    take <- is.na(idx) & !is.na(idx_chebi)
    idx[take] <- idx_chebi[take]
    match_key[take] <- "chebi_id"
  }
  if ("kegg_id" %in% names(data) && "kegg_id" %in% names(reference)) {
    idx_kegg <- best_reference_indices(data$kegg_id, reference$kegg_id, rank)
    take <- is.na(idx) & !is.na(idx_kegg)
    idx[take] <- idx_kegg[take]
    match_key[take] <- "kegg_id"
  }
  take_name <- is.na(idx) & !is.na(idx_name)
  idx[take_name] <- idx_name[take_name]
  match_key[take_name] <- "normalized_name"

  matched <- reference[idx, , drop = FALSE]
  if (length(idx) > 0) {
    missing_idx <- which(is.na(idx))
    if (length(missing_idx) > 0) {
      matched[missing_idx, ] <- NA
    }
  }
  rownames(matched) <- NULL
  matched$matched_reference_key <- match_key
  matched
}

#' Score human plasma reference evidence
#'
#' @description
#' Join input annotations to the bundled plasma reference table by HMDB,
#' PubChem CID, ChEBI, KEGG, or normalized metabolite name. Rows receive points
#' for curated plasma benchmark membership, NIST SRM1950 evidence, Ghosh 2024
#' cohort reproducibility, HMDB biofluid evidence, and serum evidence.
#'
#' @param data A data.frame or tibble with metabolite annotation information.
#' @param column_map Optional named list that maps canonical field names to input columns.
#'
#' @return The input data with matched reference identifiers, evidence-source
#'   flags, `plasma_evidence_sources`, and `plasma_evidence_score` appended.
#' @export
score_plasma_evidence <- function(data, column_map = NULL) {
  validated <- validate_annotation_table(data, column_map = column_map)
  reference <- load_plasma_core_reference()
  matched <- join_plasma_reference(validated, reference)

  plasma_benchmark_hit <- normalize_logical_flag(matched$plasma_benchmark)
  nist_hit <- normalize_logical_flag(matched$nist_srm1950)
  hmdb_biofluid_hit <- normalize_logical_flag(matched$hmdb_biofluid)
  serum_hit <- normalize_logical_flag(matched$serum_evidence)
  endogenous_hint <- normalize_logical_flag(matched$endogenous_hint)
  ghosh_plasma_hit <- if ("ghosh_2024_plasma" %in% names(matched)) {
    normalize_logical_flag(matched$ghosh_2024_plasma)
  } else {
    rep(FALSE, nrow(validated))
  }
  ghosh_all5_hit <- if ("ghosh_2024_all5_cohorts" %in% names(matched)) {
    normalize_logical_flag(matched$ghosh_2024_all5_cohorts)
  } else {
    rep(FALSE, nrow(validated))
  }
  ghosh_core_hit <- if ("ghosh_2024_core_50pct" %in% names(matched)) {
    normalize_logical_flag(matched$ghosh_2024_core_50pct)
  } else {
    rep(FALSE, nrow(validated))
  }

  score <- integer(nrow(validated))
  score <- score + ifelse(plasma_benchmark_hit, 3L, 0L)
  score <- score + ifelse(nist_hit, 3L, 0L)
  score <- score + ifelse(ghosh_core_hit, 3L, 0L)
  score <- score + ifelse(!ghosh_core_hit & ghosh_all5_hit, 2L, 0L)
  score <- score + ifelse(!ghosh_all5_hit & ghosh_plasma_hit, 1L, 0L)
  score <- score + ifelse(hmdb_biofluid_hit, 2L, 0L)
  score <- score + ifelse(serum_hit, 1L, 0L)

  sources <- character(nrow(validated))
  for (i in seq_len(nrow(validated))) {
    parts <- c(
      if (plasma_benchmark_hit[[i]]) "Plasma Benchmark",
      if (nist_hit[[i]]) "NIST SRM1950",
      if (ghosh_core_hit[[i]]) "Ghosh 2024 core plasma",
      if (!ghosh_core_hit[[i]] && ghosh_all5_hit[[i]]) "Ghosh 2024 all-five cohorts",
      if (!ghosh_all5_hit[[i]] && ghosh_plasma_hit[[i]]) "Ghosh 2024 plasma",
      if (hmdb_biofluid_hit[[i]]) "HMDB biofluid",
      if (serum_hit[[i]]) "Serum evidence"
    )
    sources[[i]] <- if (length(parts) == 0) "" else paste(parts, collapse = "; ")
  }

  validated$plasma_benchmark_hit <- plasma_benchmark_hit
  validated$nist_srm1950_hit <- nist_hit
  validated$ghosh_2024_plasma_hit <- ghosh_plasma_hit
  validated$ghosh_2024_all5_cohorts_hit <- ghosh_all5_hit
  validated$ghosh_2024_core_50pct_hit <- ghosh_core_hit
  validated$hmdb_biofluid_hit <- hmdb_biofluid_hit
  validated$serum_evidence_hit <- serum_hit
  validated$endogenous_hint <- endogenous_hint
  validated$matched_reference_key <- matched$matched_reference_key
  validated$reference_metabolite_name <- if ("metabolite_name" %in% names(matched)) {
    matched$metabolite_name
  } else {
    rep(NA_character_, nrow(validated))
  }
  validated$reference_hmdb_id <- if ("hmdb_id" %in% names(matched)) {
    matched$hmdb_id
  } else {
    rep(NA_character_, nrow(validated))
  }
  validated$reference_pubchem_cid <- if ("pubchem_cid" %in% names(matched)) {
    matched$pubchem_cid
  } else {
    rep(NA_character_, nrow(validated))
  }
  validated$reference_chebi_id <- if ("chebi_id" %in% names(matched)) {
    matched$chebi_id
  } else {
    rep(NA_character_, nrow(validated))
  }
  validated$reference_evidence_tier <- if ("evidence_tier" %in% names(matched)) {
    matched$evidence_tier
  } else {
    rep(NA_character_, nrow(validated))
  }
  validated$plasma_evidence_sources <- sources
  validated$plasma_evidence_score <- score
  coerce_tibble_if_available(validated)
}

#' Classify plasma annotation confidence
#'
#' @description
#' Combine structured annotation support, technical quality columns when
#' provided, plasma reference evidence, exogenous flags, and conservative lipid
#' handling into a final class. The main classes are
#' `core_plasma_metabolite`, `probable_plasma_metabolite`,
#' `lipid_class_only`, `exposure_related_metabolite`,
#' `remove_contaminant`, and `low_confidence_annotation`.
#'
#' @param data A data.frame or tibble containing evidence columns.
#'
#' @return The input data with confidence scores, final class, and decision
#'   reason columns appended.
#' @export
classify_annotation_confidence <- function(data) {
  validated <- validate_annotation_table(data)
  if (!"plasma_evidence_score" %in% names(validated)) {
    validated <- score_plasma_evidence(validated)
  }
  if (!"exogenous_flag" %in% names(validated) || !"contaminant_flag" %in% names(validated)) {
    validated <- flag_exogenous_compounds(validated)
  }
  if (!"is_lipid" %in% names(validated) || !"lipid_annotation_level" %in% names(validated)) {
    lipid_info <- normalize_lipid_annotation(validated$metabolite_name)
    validated$is_lipid <- lipid_info$is_lipid
    validated$lipid_class <- lipid_info$lipid_class
    validated$lipid_annotation_level <- lipid_info$lipid_annotation_level
    validated$lipid_normalized_name <- lipid_info$normalized_name
  }

  validated$annotation_evidence_score <- score_annotation_evidence(validated)
  validated$technical_quality_score <- score_technical_quality(validated)
  validated$endogenous_support_score <- ifelse(normalize_logical_flag(validated$endogenous_hint), 1L, 0L)
  validated$contaminant_penalty <- ifelse(validated$contaminant_flag %in% TRUE, 4L, 0L)
  validated$final_confidence_score <- validated$annotation_evidence_score +
    validated$technical_quality_score +
    validated$plasma_evidence_score +
    validated$endogenous_support_score -
    validated$exogenous_penalty -
    validated$contaminant_penalty

  final_class <- character(nrow(validated))
  reason <- character(nrow(validated))

  for (i in seq_len(nrow(validated))) {
    if (validated$contaminant_flag[[i]]) {
      final_class[[i]] <- "remove_contaminant"
      reason[[i]] <- "Contaminant flag triggered by reference or sample-to-blank behavior."
    } else if (
      validated$is_lipid[[i]] &&
        validated$lipid_annotation_level[[i]] != "not_lipid" &&
        validated$lipid_annotation_level[[i]] != "molecular_species"
    ) {
      final_class[[i]] <- "lipid_class_only"
      reason[[i]] <- "Lipid annotation retained conservatively at class or sum-composition level."
    } else if (validated$exogenous_flag[[i]]) {
      final_class[[i]] <- "exposure_related_metabolite"
      reason[[i]] <- "Exogenous evidence outweighs endogenous plasma interpretation."
    } else if (
      validated$plasma_evidence_score[[i]] >= 6 &&
        validated$annotation_evidence_score[[i]] >= 2 &&
        validated$technical_quality_score[[i]] >= 2
    ) {
      final_class[[i]] <- "core_plasma_metabolite"
      reason[[i]] <- "Strong plasma evidence plus adequate annotation and technical support."
    } else if (
      validated$plasma_evidence_score[[i]] >= 2 ||
        validated$annotation_evidence_score[[i]] >= 2
    ) {
      final_class[[i]] <- "probable_plasma_metabolite"
      reason[[i]] <- "Some structured evidence exists, but support is not strong enough for the core tier."
    } else {
      final_class[[i]] <- "low_confidence_annotation"
      reason[[i]] <- "Insufficient plasma or annotation evidence for a stronger class."
    }
  }

  validated$final_annotation_class <- final_class
  validated$decision_reason <- reason
  coerce_tibble_if_available(validated)
}
