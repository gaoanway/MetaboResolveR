load_reference_csv <- function(filename) {
  path <- system.file("extdata", filename, package = "MetaboResolveR")
  if (!nzchar(path)) {
    path <- file.path("inst", "extdata", filename)
  }
  utils::read.csv(path, stringsAsFactors = FALSE)
}

load_plasma_core_reference <- function() {
  ref <- load_reference_csv("plasma_core_reference.csv")
  ref$normalized_name <- normalize_lookup_key(ref$normalized_name)
  ref$hmdb_id <- normalize_hmdb(ref$hmdb_id)
  if ("pubchem_cid" %in% names(ref)) {
    ref$pubchem_cid <- normalize_pubchem(ref$pubchem_cid)
  }
  if ("chebi_id" %in% names(ref)) {
    ref$chebi_id <- normalize_chebi(ref$chebi_id)
  }
  if ("kegg_id" %in% names(ref)) {
    ref$kegg_id <- toupper(trimws(as.character(ref$kegg_id)))
    ref$kegg_id[ref$kegg_id %in% c("", "NA", "NAN", "NULL")] <- NA_character_
  }
  ref
}

load_exogenous_flags_reference <- function() {
  ref <- load_reference_csv("exogenous_flags_reference.csv")
  ref$normalized_name <- normalize_lookup_key(ref$normalized_name)
  ref
}

load_lipid_name_rules <- function() {
  load_reference_csv("lipid_name_rules.csv")
}

#' Load the bundled full plasma metabolite evidence table
#'
#' @description
#' Read the package's merged reference table. This table keeps source-specific
#' evidence columns so users can audit why a metabolite is considered supported
#' in human plasma, serum, or reference-material evidence.
#'
#' @return A data.frame with merged source evidence, identifiers, and tiers.
#' @export
load_plasma_metabolite_evidence_reference <- function() {
  load_reference_csv("plasma_metabolite_evidence_reference.csv")
}

#' Load the bundled reference source catalog
#'
#' @description
#' Read the provenance catalog describing the papers and databases used to build
#' the bundled reference table, including source type, role, and update notes.
#'
#' @return A data.frame describing the provenance sources used by the package.
#' @export
load_reference_source_catalog <- function() {
  load_reference_csv("reference_source_catalog.csv")
}
