# Load the bundled full plasma metabolite evidence table

Read the package's merged reference table. This table keeps
source-specific evidence columns so users can audit why a metabolite is
considered supported in human plasma, serum, or reference-material
evidence.

## Usage

``` r
load_plasma_metabolite_evidence_reference()
```

## Value

A data.frame with merged source evidence, identifiers, and tiers.
