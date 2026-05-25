# Phase 2 Task: Documentation And Vignettes

**Goal:** Make the R package understandable to users, reviewers, and future
developers through proper function documentation and narrative vignettes.

## Deliverables

- [x] Roxygen-style documentation comments for every exported function.
- [x] Dedicated `man/*.Rd` help pages generated from roxygen.
- [x] `vignettes/plasmaAnnotateR-real-case.Rmd`
- [x] `vignettes/plasma-reference-database.Rmd`
- [x] `vignettes/identifier-only-inputs.Rmd`
- [x] Optional `_pkgdown.yml`
- [x] A small public synthetic fixture in `inst/extdata`.

## Documentation Tasks

- [x] Confirm `roxygen2` availability.
- [x] Replace the grouped manual page with roxygen-generated docs.
- [x] Document user-facing functions:
  - `annotate_plasma_metabolites()`
  - `score_plasma_evidence()`
  - `classify_annotation_confidence()`
  - `flag_exogenous_compounds()`
  - `normalize_lipid_annotation()`
  - `load_reference_source_catalog()`
  - `load_plasma_metabolite_evidence_reference()`
  - `export_annotation_report()`
- [x] Document accepted input aliases:
  - `HMDB`, `HMID`, `hmdb_id`
  - `PubChem CID`, `pubchem_cid`
  - `ChEBI ID`, `chebi_id`
  - `KEGG`, `kegg_id`
  - `LIPIDMAPS_ID`, `lipidmaps_id`
- [x] Document evidence tiers and final annotation classes.

## Vignette Tasks

- [x] Confirm Pandoc availability through the RStudio/Quarto Pandoc path.
- [x] Re-enable vignettes in package build.
- [x] Write a synthetic real-case vignette that mirrors the private `.xlsx`
  workflow without exposing private data.
- [x] Write a reference database vignette explaining:
  - source hierarchy.
  - SRM1950-DB.
  - Ghosh 2024.
  - Serum Metabolome/HMDB.
  - Plasma Benchmark limitation and future import.
- [x] Write an identifier-only vignette showing HMDB/PubChem/ChEBI/KEGG input.
- [x] Re-enable vignettes in package build once they can be rendered.

## Success Criteria

- `R CMD check --no-manual` returns `Status: OK`.
- Function help pages are clear enough for collaborators to use the package.
- At least one vignette demonstrates a full import-to-report workflow.
- No private real data are included in public docs.
