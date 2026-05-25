#' Flag exogenous or contaminant-like compounds
#'
#' @description
#' Add conservative flags for compounds that are usually interpreted as
#' exposure-related, drug/food-derived, or technical contaminants. A
#' sample-to-blank ratio below 3 also triggers a contaminant flag when that
#' column is supplied.
#'
#' @param data A data.frame or tibble with metabolite annotation information.
#' @param column_map Optional named list that maps canonical field names to input columns.
#'
#' @return The input data with exogenous category, source, flag, contaminant
#'   flag, and penalty columns appended.
#' @export
flag_exogenous_compounds <- function(data, column_map = NULL) {
  validated <- validate_annotation_table(data, column_map = column_map)
  reference <- load_exogenous_flags_reference()
  idx <- match(validated$normalized_name, reference$normalized_name)
  matched <- reference[idx, , drop = FALSE]
  rownames(matched) <- NULL

  category <- ifelse(is.na(matched$flag_category), "", matched$flag_category)
  penalty <- suppressWarnings(as.integer(matched$default_penalty))
  penalty[is.na(penalty)] <- 0L

  exogenous_flag <- nzchar(category) & category != "technical_contaminant"
  contaminant_flag <- category == "technical_contaminant"

  if ("sample_blank_ratio" %in% names(validated)) {
    contaminant_flag <- contaminant_flag | (!is.na(validated$sample_blank_ratio) & validated$sample_blank_ratio < 3)
  }

  validated$exogenous_category <- category
  validated$exogenous_source_db <- ifelse(is.na(matched$source_db), "", matched$source_db)
  validated$exogenous_flag <- exogenous_flag
  validated$contaminant_flag <- contaminant_flag
  validated$exogenous_penalty <- penalty
  coerce_tibble_if_available(validated)
}
