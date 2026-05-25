#' Annotate human plasma metabolite tables
#'
#' @description
#' Run the full plasma-aware annotation refinement workflow on a post-search
#' LC-MS metabolite table. The workflow standardizes common identifier columns,
#' normalizes lipid names conservatively, joins bundled human plasma reference
#' evidence, flags exogenous or contaminant-like compounds, and assigns a final
#' annotation class.
#'
#' @param data A data.frame or tibble containing metabolite annotations.
#' @param column_map Optional named list mapping canonical field names to input
#'   columns. Most common aliases, including `Name`, `HMDB_ID`, `HMID`,
#'   `PubChemID`, `KEGG_ID`, `Lipidmaps_ID`, `m/z`, `RT (min)`, `IonMode`, and
#'   `Score`, are detected automatically.
#'
#' @return The input table with standardized identifiers, plasma evidence,
#'   exogenous flags, lipid-normalization fields, confidence scores, and
#'   `final_annotation_class` appended. A tibble is returned when available.
#' @export
annotate_plasma_metabolites <- function(data, column_map = NULL) {
  validated <- validate_annotation_table(data, column_map = column_map)
  lipid_info <- normalize_lipid_annotation(validated$metabolite_name)

  validated$lipid_normalized_name <- lipid_info$normalized_name
  validated$lipid_class <- lipid_info$lipid_class
  validated$lipid_annotation_level <- lipid_info$lipid_annotation_level
  validated$is_lipid <- lipid_info$is_lipid
  validated$normalized_name <- ifelse(
    lipid_info$is_lipid,
    normalize_lookup_key(lipid_info$normalized_name),
    validated$normalized_name
  )

  scored <- score_plasma_evidence(validated)
  flagged <- flag_exogenous_compounds(scored)
  classified <- classify_annotation_confidence(flagged)
  coerce_tibble_if_available(classified)
}

#' Export an annotation report to CSV
#'
#' @description
#' Write an annotated table to CSV. If the input has not yet been annotated,
#' `annotate_plasma_metabolites()` is called first. A compact final-class
#' summary can be written beside the report for quick review.
#'
#' @param data An annotated data.frame or a raw input table.
#' @param path Output CSV path.
#' @param include_summary Whether to also write a final-class summary count CSV.
#'
#' @return Invisibly returns a list of written file paths.
#' @export
export_annotation_report <- function(data, path, include_summary = TRUE) {
  annotated <- data
  if (!"final_annotation_class" %in% names(annotated)) {
    annotated <- annotate_plasma_metabolites(annotated)
  }

  utils::write.csv(annotated, path, row.names = FALSE, na = "")
  outputs <- list(report = path)

  if (isTRUE(include_summary)) {
    summary_path <- sub("\\.csv$", "_summary.csv", path, ignore.case = TRUE)
    if (identical(summary_path, path)) {
      summary_path <- paste0(path, "_summary.csv")
    }
    summary_tbl <- as.data.frame(table(annotated$final_annotation_class), stringsAsFactors = FALSE)
    names(summary_tbl) <- c("final_annotation_class", "n")
    utils::write.csv(summary_tbl, summary_path, row.names = FALSE, na = "")
    outputs$summary <- summary_path
  }

  invisible(outputs)
}
