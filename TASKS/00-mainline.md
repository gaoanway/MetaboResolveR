# Mainline Project Task

**Goal:** Turn `plasmaAnnotateR` into a public, tested, documented, and
publication-ready R package for human plasma untargeted metabolomics annotation
review, with a manuscript aimed first at `Metabolism`.

**Current Baseline**

- Package builds and checks successfully as of the last validation pass.
- Current bundled reference database contains:
  - 42,817 merged evidence rows.
  - 1,058 SRM1950-DB rows.
  - 1,915 `Tier 1_gold_or_core_plasma` rows.
  - PubChem, ChEBI, KEGG, HMDB/HMID identifier matching.
- ID-only input is supported for HMDB/HMID, PubChem CID, ChEBI, and KEGG.
- The real-case dataset is local-only and excluded from public release.

## Mainline Milestones

- [x] **M1: Real-case validation completed locally**
  - Split the `.xlsx` real annotation file into ten local chunks.
  - Run package annotation on every chunk.
  - Confirm 1,416 observed input rows and 1,416 annotated output rows.
  - Produce a local real-case summary table.

- [x] **M2: Real-case findings translated into package improvements**
  - Add schema-level tests based on discovered real columns.
  - Add local-only smoke tests that skip when real chunks are absent.
  - Improve column-map ergonomics for HMDB/KEGG/LipidMaps vendor outputs.

- [x] **M3: Documentation and vignettes completed**
  - Generate dedicated `.Rd` documentation from roxygen comments.
  - Write a real-case vignette using anonymized or synthetic data.
  - Write a reference-database vignette.
  - Write an identifier-only-input vignette.

- [ ] **M4: Public GitHub repository established**
  - [x] Initialize git if not already initialized.
  - [x] Add `.gitignore` before any commit.
  - [ ] Push package source to a public GitHub repository.
  - [x] Add GitHub Actions R CMD check.
  - [ ] Confirm Actions pass.

- [ ] **M5: Metabolism manuscript drafted**
  - Choose a biological story around human plasma metabolite annotation quality.
  - Generate figures and tables from package outputs.
  - Draft manuscript sections.
  - Align repository, package version, and manuscript outputs.

## Global Non-Negotiables

- Real data must remain local-only unless the user explicitly approves a
  sanitized derivative.
- GitHub will be public, so `.gitignore` must be in place before the first
  public push.
- The `.xlsx` file is the official real-case input.
- `Metabolism` is the first manuscript target; `Bioinformatics` remains a
  backup only if the framing shifts toward software-method novelty.

## Suggested Version Tags

- `v0.1.0-realcase`: real-case testing complete.
- `v0.2.0-docs`: documentation and vignettes complete.
- `v0.3.0-ci`: public GitHub and CI complete.
- `v0.4.0-manuscript`: manuscript-ready release.
