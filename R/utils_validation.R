canonical_column_map <- function() {
  list(
    metabolite_name = c("metabolite_name", "Metabolites", "metabolites", "Name", "name", "compound_name"),
    hmdb_id = c("hmdb_id", "HMDB", "hmdb", "HMDB_ID", "HMDB ID", "HMID", "hmid", "hmdb_accession", "HMDBID"),
    kegg_id = c("kegg_id", "KEGG", "kegg", "KEGG_ID", "KEGG ID", "KEGGID"),
    pubchem_cid = c(
      "pubchem_cid",
      "PUBCHEM",
      "pubchem",
      "PubChem",
      "PubChemID",
      "PubChem CID",
      "PUBCHEM_CID",
      "PUBCHEM_ID",
      "cid"
    ),
    chebi_id = c("chebi_id", "CHEBI", "chebi", "ChEBI", "CHEBI_ID", "ChEBI ID", "ChEBI_ID"),
    lipidmaps_id = c(
      "lipidmaps_id",
      "LIPIDMAPS_ID",
      "Lipidmaps_ID",
      "LipidMaps_ID",
      "LIPIDMAPS",
      "lipidmaps"
    ),
    formula = c("formula", "FORMULA", "Formula"),
    adduct = c("adduct", "ADDUCT", "Adduct"),
    mz = c("mz", "m/z", "precursor_mz"),
    retention_time = c("retention_time", "rt", "RT", "RT (min)", "RETENTION_TIME"),
    polarity = c("polarity", "POLARITY", "IonMode", "ion_mode", "Ion Mode"),
    ms2_score = c("ms2_score", "MS2_score", "similarity_score", "Score", "score"),
    qc_rsd = c("qc_rsd", "QC_RSD", "RSD"),
    sample_blank_ratio = c("sample_blank_ratio", "sample_to_blank", "sample_blank"),
    missing_rate = c("missing_rate", "MissingRate", "missing")
  )
}

missing_string_tokens <- function() {
  c("", "-", "--", "NA", "N/A", "NAN", "NULL", "NONE", "NOT AVAILABLE")
}

coerce_tibble_if_available <- function(x) {
  if (requireNamespace("tibble", quietly = TRUE)) {
    return(tibble::as_tibble(x))
  }
  x
}

first_present_column <- function(data, candidates) {
  present <- candidates[candidates %in% names(data)]
  if (length(present) == 0) {
    return(NULL)
  }
  present[[1]]
}

normalize_text <- function(x) {
  out <- trimws(as.character(x))
  out[is.na(x)] <- NA_character_
  out
}

normalize_lookup_key <- function(x) {
  out <- tolower(trimws(as.character(x)))
  out[toupper(out) %in% missing_string_tokens()] <- NA_character_
  out
}

normalize_hmdb <- function(x) {
  out <- toupper(trimws(as.character(x)))
  out[out %in% missing_string_tokens()] <- NA_character_
  out
}

normalize_pubchem <- function(x) {
  out <- trimws(as.character(x))
  out <- sub("^CID[:[:space:]]*", "", out, ignore.case = TRUE)
  out <- sub("[.]0$", "", out)
  out[toupper(out) %in% missing_string_tokens()] <- NA_character_
  out
}

normalize_chebi <- function(x) {
  out <- toupper(trimws(as.character(x)))
  out <- sub("^CHEBI:", "", out)
  out <- sub("[.]0$", "", out)
  out[out %in% missing_string_tokens()] <- NA_character_
  out
}

normalize_lipidmaps_id <- function(x) {
  out <- toupper(trimws(as.character(x)))
  out[out %in% missing_string_tokens()] <- NA_character_
  out
}

normalize_logical_flag <- function(x) {
  out <- tolower(trimws(as.character(x)))
  out %in% c("true", "1", "t", "yes")
}

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

validate_annotation_table <- function(data, column_map = NULL) {
  if (!is.data.frame(data)) {
    stop("`data` must be a data.frame or tibble.", call. = FALSE)
  }

  out <- data
  mapping <- canonical_column_map()
  user_map <- column_map %||% list()

  for (canonical in names(mapping)) {
    chosen <- user_map[[canonical]] %||% first_present_column(out, mapping[[canonical]])
    if (!is.null(chosen) && chosen %in% names(out) && !canonical %in% names(out)) {
      out[[canonical]] <- out[[chosen]]
    }
  }

  identity_cols <- c("metabolite_name", "hmdb_id", "kegg_id", "pubchem_cid", "chebi_id", "lipidmaps_id")
  identity_present <- identity_cols[identity_cols %in% names(out)]
  if (length(identity_present) == 0) {
    stop(
      paste(
        "Input must contain at least one annotation identity column such as",
        "metabolite_name, hmdb_id, kegg_id, pubchem_cid, chebi_id, or",
        "lipidmaps_id."
      ),
      call. = FALSE
    )
  }

  if (!"metabolite_name" %in% names(out)) {
    out$metabolite_name <- NA_character_
  }

  out$metabolite_name <- normalize_text(out$metabolite_name)
  out$normalized_name <- normalize_lookup_key(out$metabolite_name)

  if ("hmdb_id" %in% names(out)) {
    out$hmdb_id <- normalize_hmdb(out$hmdb_id)
  }
  if ("pubchem_cid" %in% names(out)) {
    out$pubchem_cid <- normalize_pubchem(out$pubchem_cid)
  }
  if ("chebi_id" %in% names(out)) {
    out$chebi_id <- normalize_chebi(out$chebi_id)
  }
  if ("kegg_id" %in% names(out)) {
    out$kegg_id <- toupper(trimws(as.character(out$kegg_id)))
    out$kegg_id[out$kegg_id %in% missing_string_tokens()] <- NA_character_
  }
  if ("lipidmaps_id" %in% names(out)) {
    out$lipidmaps_id <- normalize_lipidmaps_id(out$lipidmaps_id)
  }

  numeric_fields <- c("mz", "retention_time", "ms2_score", "qc_rsd", "sample_blank_ratio", "missing_rate")
  for (field in numeric_fields) {
    if (field %in% names(out)) {
      suppressWarnings(out[[field]] <- as.numeric(out[[field]]))
    }
  }

  coerce_tibble_if_available(out)
}
