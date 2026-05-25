for (file in list.files("R", pattern = "[.]R$", full.names = TRUE)) {
  source(file)
}

catalog <- load_reference_source_catalog()
stopifnot(nrow(catalog) >= 8)

evidence <- load_plasma_metabolite_evidence_reference()
stopifnot(nrow(evidence) == 42817)

reference <- load_plasma_core_reference()
stopifnot(nrow(reference) == 42817)
stopifnot(!anyDuplicated(reference$normalized_name))

scored <- score_plasma_evidence(
  data.frame(
    metabolite_name = c("Glucose", "Spermidine", "Mystery"),
    hmdb_id = c("HMDB0000122", NA, NA),
    stringsAsFactors = FALSE
  )
)

print(scored[, c(
  "metabolite_name",
  "plasma_evidence_score",
  "plasma_evidence_sources"
)])

stopifnot(scored$plasma_evidence_score[[1]] > scored$plasma_evidence_score[[3]])
stopifnot(grepl("Ghosh 2024 core plasma", scored$plasma_evidence_sources[[1]]))
stopifnot(scored$ghosh_2024_core_50pct_hit[[1]])

id_only <- score_plasma_evidence(
  data.frame(
    hmdb_id = c("HMDB0000122", NA, NA),
    pubchem_cid = c(NA, "1102", NA),
    chebi_id = c(NA, NA, "15903"),
    stringsAsFactors = FALSE
  )
)

print(id_only[, c(
  "metabolite_name",
  "reference_metabolite_name",
  "plasma_evidence_score",
  "plasma_evidence_sources"
)])

stopifnot(id_only$plasma_evidence_score[[1]] > 0)
stopifnot(id_only$reference_metabolite_name[[1]] != "")
stopifnot(id_only$matched_reference_key[[1]] == "hmdb_id")
stopifnot(id_only$plasma_evidence_score[[2]] > 0)
stopifnot(id_only$matched_reference_key[[2]] == "pubchem_cid")
stopifnot(id_only$plasma_evidence_score[[3]] > 0)
stopifnot(id_only$matched_reference_key[[3]] == "chebi_id")

message("plasma reference database verification passed")
