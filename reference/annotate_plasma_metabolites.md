# Annotate human plasma metabolite tables

Run the full plasma-aware annotation refinement workflow on a
post-search LC-MS metabolite table. The workflow standardizes common
identifier columns, normalizes lipid names conservatively, joins bundled
human plasma reference evidence, flags exogenous or contaminant-like
compounds, and assigns a final annotation class.

## Usage

``` r
annotate_plasma_metabolites(data, column_map = NULL)
```

## Arguments

- data:

  A data.frame or tibble containing metabolite annotations.

- column_map:

  Optional named list mapping canonical field names to input columns.
  Most common aliases, including \`Name\`, \`HMDB_ID\`, \`HMID\`,
  \`PubChemID\`, \`KEGG_ID\`, \`Lipidmaps_ID\`, \`m/z\`, \`RT (min)\`,
  \`IonMode\`, and \`Score\`, are detected automatically.

## Value

The input table with standardized identifiers, plasma evidence,
exogenous flags, lipid-normalization fields, confidence scores, and
\`final_annotation_class\` appended. A tibble is returned when
available.
