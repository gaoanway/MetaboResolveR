# Phase 1 Task: Local Real-Case Testing

**Goal:** Validate `MetaboResolveR` on the real metabolite annotation
file and convert any real-world failures into package tests and fixes.

**Observed Row Count:** The official `.xlsx` workbook currently reads as
1,416 data rows in R, not 1,417. All validation outputs should report the
observed row count unless the source workbook is revised.

**Official Input**

Local private workbook:

`meta_intensity_all_hmdb_kegg_lipidmaps.xlsx`

Set `PLASMA_ANNOTATER_REAL_CASE_XLSX` locally before running the private
validation workflow.

**Privacy Decision**

The real file, split chunks, and direct annotated outputs are local-only and
must not be committed to GitHub.

## Deliverables

- [x] `data-raw/real_case/README.md`
- [x] `data-raw/real_case/split_real_case.R`
- [x] `data-raw/real_case/run_real_case_validation.R`
- [x] `data-raw/real_case/chunks/chunk_01.csv` through `chunk_10.csv`
- [x] `data-raw/real_case/results/real_case_annotation_summary.csv`
- [x] `data-raw/real_case/results/real_case_class_counts.csv`
- [x] `data-raw/real_case/results/real_case_identifier_coverage.csv`
- [x] `tests/testthat/test-real-case-schema.R`
- [x] `tests/testthat/test-real-case-chunk-smoke.R`

## Implementation Plan

- [x] Inspect workbook sheets and column names.
- [x] Confirm the exact row count from R import is 1,416.
- [ ] Identify columns that map to:
  - `metabolite_name`
  - `hmdb_id`
  - `kegg_id`
  - `lipidmaps_id`
  - `formula`
  - `mz`
  - `retention_time`
  - `polarity`
  - `ms2_score`
  - `qc_rsd`
  - `sample_blank_ratio`
  - `missing_rate`
- [x] Add automatic aliases for this file's schema.
- [x] Split rows into ten chunks:
  - `chunk_01.csv` to `chunk_09.csv`: about 142 rows each.
  - `chunk_10.csv`: remaining rows.
- [x] Run `annotate_plasma_metabolites()` on each chunk.
- [x] Capture errors, warnings, and row counts for each chunk.
- [x] Merge annotated chunk summaries.
- [x] Confirm annotated row count equals 1,416.
- [x] Summarize final classes.
- [x] Summarize evidence-source hits.
- [x] Summarize identifier coverage.
- [x] Extract review tables:
  - top high-confidence endogenous plasma metabolites.
  - exposure-related metabolites.
  - contaminants/removal candidates.
  - lipid class-only annotations.
  - unmatched or low-confidence annotations.
- [ ] Review biological plausibility of the summary with the user before
  changing scoring thresholds.

## Success Criteria

- All ten chunks run without R errors. **Done.**
- The merged annotated result has exactly 1,416 observed rows. **Done.**
- Local-only outputs are excluded by `.gitignore`. **Done.**
- At least one synthetic or schema-derived test is added to `tests/testthat`. **Done.**
- Real-case summary is ready to support a vignette and manuscript figure. **Done.**

## Follow-Up Decisions Needed After First Run

- Which class distribution looks biologically plausible?
- Which unmatched annotations should be manually mapped?
- Should lipid handling become stricter or more permissive?
- Should exposure-related metabolites be retained, downweighted, or separated?
