# MetaboResolveR

`MetaboResolveR` resolves post-identification untargeted human plasma
metabolomics tables into plasma-aware annotation outputs. It is built
for LC-MS annotation review workflows where the input table already
contains candidate metabolite names or database IDs.

## Core Workflow

``` r

library(MetaboResolveR)

input <- data.frame(
  Name = c("Glucose", "Caffeine", "Unknown feature"),
  HMDB_ID = c("HMDB0000122", "HMDB0001847", "-"),
  PubChemID = c("5793", "2519", "-"),
  Score = c(0.95, 0.88, 0.50),
  check.names = FALSE
)

annotated <- annotate_plasma_metabolites(input)
annotated[, c("metabolite_name", "matched_reference_key", "final_annotation_class")]
```

## Install From GitHub

After the public repository is created:

``` r

install.packages("remotes")
remotes::install_github("gaoanway/MetaboResolveR")
```

## What It Adds

- Canonical column handling for names, HMDB/HMID, PubChem CID, ChEBI,
  KEGG, LipidMaps, m/z, retention time, polarity, and MS2 score.
- Human plasma evidence scoring from bundled reference sources.
- Identifier-only matching when the user has IDs but no reliable name.
- Conservative lipid handling for class-only or sum-composition
  annotations.
- Exogenous and contaminant flags for review.
- Final classes such as `core_plasma_metabolite`,
  `probable_plasma_metabolite`, `lipid_class_only`, and
  `low_confidence_annotation`.

## Key Files

- `inst/extdata/reference_source_catalog.csv`: provenance catalog.
- `inst/extdata/plasma_metabolite_evidence_reference.csv`: merged
  evidence table.
- `inst/extdata/example_real_case_schema.csv`: public synthetic fixture
  matching the private real-case schema.
- `docs/human_plasma_metabolite_reference_database.md`: source hierarchy
  and rebuild notes.
- `vignettes/`: narrative examples included in package build when Pandoc
  is available to R.
- `data-raw/real_case/`: local-only real workbook split and validation
  workflow; excluded from Git because it contains private derived
  outputs.
