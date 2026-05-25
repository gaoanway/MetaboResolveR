# Score human plasma reference evidence

Join input annotations to the bundled plasma reference table by HMDB,
PubChem CID, ChEBI, KEGG, or normalized metabolite name. Rows receive
points for curated plasma benchmark membership, NIST SRM1950 evidence,
Ghosh 2024 cohort reproducibility, HMDB biofluid evidence, and serum
evidence.

## Usage

``` r
score_plasma_evidence(data, column_map = NULL)
```

## Arguments

- data:

  A data.frame or tibble with metabolite annotation information.

- column_map:

  Optional named list that maps canonical field names to input columns.

## Value

The input data with matched reference identifiers, evidence-source
flags, \`plasma_evidence_sources\`, and \`plasma_evidence_score\`
appended.
