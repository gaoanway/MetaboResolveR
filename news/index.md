# Changelog

## MetaboResolveR 0.0.0.9000

### Phase 1 and Phase 2 local milestone

- Added local-only real-case split and validation scripts for the
  official `.xlsx` workbook.
- Split the real workbook into ten local chunks and annotated all 1,416
  observed rows without chunk errors.
- Added automatic aliases for vendor-style columns including `Name`,
  `HMDB_ID`, `KEGG_ID`, `Lipidmaps_ID`, `PubChemID`, `RT (min)`,
  `IonMode`, and `Score`.
- Treated placeholder identifiers such as `-` and `N/A` as missing
  values.
- Added schema, fixture, and local chunk smoke tests.
- Added public synthetic real-case fixture plus vignettes for the
  real-case workflow, reference database, and identifier-only inputs.
- Updated grouped function documentation and README.
- Generated dedicated roxygen2 help pages, moved `NAMESPACE` under
  roxygen2 management, and re-enabled vignette building with Pandoc.
- Added auditable SRM1950 source-name corrections for two corrupted
  Unicode names before public repository setup.
