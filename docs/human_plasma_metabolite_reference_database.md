# Human plasma metabolite reference database

Updated: 2026-05-18

This document defines the source hierarchy, evidence rules, and generated
tables used by `MetaboResolveR` for human plasma untargeted metabolomics
annotation review.

## Goal

The database is not a generic metabolite name list. Its purpose is to answer:

> When an untargeted LC-MS annotation reports a compound, how much external
> evidence supports that compound as a real human plasma or blood metabolite?

The database therefore keeps broad evidence rows, but separates them into
tiers. Only the highest tiers should be interpreted as strong plasma-presence
evidence.

## Source hierarchy

### Tier 1: gold/reference-material evidence

These sources define the strongest evidence class.

- NIST SRM 1950: human plasma standard reference material and QC anchor.
- SRM1950-DB 2025: high-confidence concentration reference database for NIST
  SRM 1950.
- Plasma Benchmark 2025: plasma-centric LC-MS benchmark for robustly detectable
  metabolites and lipids. The Nature Metabolism correspondence reports 639
  robust molecular features and 288 manually curated unique metabolites in the
  online tool/database.
- Manual package seed overrides: a small set of common metabolites retained
  from the package scaffold until all gold-source exports are available.

Operational rule: a compound can enter the strongest tier when it has imported
SRM1950-DB support, NIST/SRM manual support, Plasma Benchmark support, or when
it is in the Ghosh 2024 large-cohort core plasma set.

### Tier 2: large-cohort human plasma evidence

Primary imported source:

- Ghosh et al. 2024, *Analysis of plasma metabolomes from 11,309 individuals*,
  Scientific Reports. The imported supplementary table contains 1,629
  untargeted LC-MS plasma metabolites across MDCS, PIVUS, POEM, SCAPIS-M, and
  SCAPIS-U cohorts.

Operational rules:

- `ghosh_2024_all5_cohorts = TRUE`: reported in all five cohorts.
- `ghosh_2024_core_50pct = TRUE`: reported in all five cohorts and
  `max_missingness <= 50` in the supplementary table.

The parsed supplementary table currently yields 1,066 all-five-cohort rows and
912 rows meeting the core missingness rule.

### Tier 3: serum/plasma compendium evidence

Primary imported source:

- Serum Metabolome Database / HMDB serum XML download. This is based on the
  Psychogios et al. 2011 serum/plasma compendium and current HMDB-style
  biofluid records.

Important handling rule:

- The current XML download is broad: 40,678 rows. It contains `quantified`,
  `detected`, `expected`, and a small number of other statuses.
- `expected` rows are retained in the broad evidence table for lookup and
  identifier mapping, but they are not treated as plasma evidence in the scoring
  table.
- `hmdb_biofluid` and `serum_evidence` are set only when a row is
  `detected`/`quantified` or has normal blood/serum/plasma concentration
  entries.

### Tier 4: supporting or expected evidence

This tier includes rows retained for future curation, name matching, or
identifier mapping, but not as strong evidence that the metabolite is certainly
present in human plasma.

Examples:

- HMDB/Serum Metabolome rows with `expected` status and no normal blood/serum
  concentration support.
- Integrative or secondary sources such as HUBMet, Blood Exposome, FooDB,
  DrugBank, ChEBI, LIPID MAPS, and RefMet. These are cataloged for future
  curation, exogenous flagging, and nomenclature support.

## Generated files

### Raw downloads

- `data-raw/serum_metabolites.zip`
  Official Serum Metabolome XML download.
- `data-raw/ghosh_2024_supplementary_table_2.xlsx`
  Ghosh 2024 supplementary workbook downloaded from the Nature/Springer static
  supplement.
- `data-raw/srm1950_data_2025.csv`
  SRM1950-DB 2025 CSV downloaded from the SRM1950-DB download endpoint.
- `data-raw/manual_curated_reference_overrides.csv`
  Small manual seed table for gold-standard scaffold examples.
- `data-raw/manual_source_name_corrections.csv`
  Auditable corrections for source rows whose names contain corrupted or
  misleading Unicode characters while identifiers point to a canonical HMDB
  metabolite.

### Processed intermediates

- `data-raw/processed/serum_metabolome_hmdb_parsed.csv`
  Parsed HMDB/Serum Metabolome identifiers, formulas, InChIKeys, taxonomy,
  biospecimen locations, concentration counts, and PubMed IDs.
- `data-raw/processed/ghosh_2024_plasma_metabolomes.csv`
  Parsed Ghosh 2024 plasma metabolites and cohort missingness flags.
- `data-raw/processed/srm1950_db_2025_reference.csv`
  Parsed SRM1950-DB gold/reference-material rows.

### Package data

- `inst/extdata/plasma_metabolite_evidence_reference.csv`
  Full merged evidence table. This is the broad provenance table.
- `inst/extdata/plasma_core_reference.csv`
  Compact scoring table read by `score_plasma_evidence()`.
- `inst/extdata/reference_source_catalog.csv`
  Source catalog with role, URL, citation text, update strategy, and notes.
- `inst/extdata/plasma_reference_data_dictionary.csv`
  Field-level data dictionary.

## Current build counts

| Category | Rows |
|---|---:|
| Serum Metabolome/HMDB parsed rows | 40,678 |
| Ghosh 2024 plasma rows | 1,629 |
| SRM1950-DB imported rows | 1,058 |
| Manual seed overrides | 6 |
| Merged evidence rows | 42,817 |
| Ghosh all-five-cohort rows | 1,066 |
| Ghosh core missingness rows | 912 |
| Rows with scoring-ready HMDB/serum biofluid evidence | 21,470 |
| Rows with PubChem CID mapping | 27,356 |
| Rows with ChEBI mapping | 6,245 |
| Rows with KEGG mapping | 3,229 |

Evidence tier counts in the merged table:

| Evidence tier | Rows | Interpretation |
|---|---:|---|
| `Tier 1_gold_or_core_plasma` | 1,915 | SRM1950-DB, NIST/Plasma Benchmark seed evidence, or Ghosh core plasma support. |
| `Tier 2_probable_plasma` | 2,917 | Probable plasma support, including quantified serum/HMDB and all-five Ghosh rows. |
| `Tier 3_serum_plasma_compendium` | 17,530 | Detected/quantified serum or blood-adjacent compendium support. |
| `Tier 3_plasma_detected` | 437 | Ghosh plasma-reported rows not meeting stronger cohort rules. |
| `Tier 4_expected_or_supporting` | 20,018 | Expected/supporting rows retained for matching, not strong plasma evidence. |

## Annotation scoring use

`score_plasma_evidence()` now uses these source flags:

- `plasma_benchmark`: +3
- `nist_srm1950`: +3
- `ghosh_2024_core_50pct`: +3
- `ghosh_2024_all5_cohorts` without core flag: +2
- `ghosh_2024_plasma` without all-five flag: +1
- `hmdb_biofluid`: +2
- `serum_evidence`: +1

This makes the large-cohort human plasma evidence visible to the package while
keeping broad HMDB/Serum Metabolome rows from automatically becoming core
plasma calls.

ID-only input is supported. `score_plasma_evidence()` can match rows using, in
priority order, `hmdb_id`, `pubchem_cid`, `chebi_id`, `kegg_id`, then normalized
metabolite name. This means a user can provide only an HMDB/HMID-style column,
PubChem CID, ChEBI ID, or KEGG ID and still receive a plasma evidence score,
matched reference name, matched identifier key, and reference evidence tier.
Common input aliases such as `HMDB`, `HMID`, `PubChem CID`, `ChEBI ID`, and
`KEGG` are normalized during validation.

## Rebuild command

From the package root:

```powershell
py data-raw\build_plasma_reference_database.py
```

The script regenerates all processed CSVs and package `inst/extdata` reference
tables.

## Limitations and next curation steps

- Serum and plasma are related but not identical. Serum evidence supports
  blood-adjacent presence but should not be overinterpreted as strict plasma
  confirmation.
- Ghosh 2024 uses Metabolon `CHEM_ID` values and names; many rows do not carry
  public HMDB/ChEBI/PubChem identifiers in the supplement and need later ID
  mapping.
- Plasma Benchmark remains a key gold-standard source in the catalog. Its
  domain was not accessible through the permitted browser path in this session,
  so the current build keeps Plasma Benchmark as catalog/manual-seed evidence
  until an export table is available locally. Once available, those 288 curated
  metabolites should be imported as `plasma_benchmark = TRUE`.
- Xenobiotics and food/drug/exposure compounds can be real blood/plasma
  detections, but they should be labeled separately from endogenous core
  metabolism in downstream reporting.
