# Classify plasma annotation confidence

Combine structured annotation support, technical quality columns when
provided, plasma reference evidence, exogenous flags, and conservative
lipid handling into a final class. The main classes are
\`core_plasma_metabolite\`, \`probable_plasma_metabolite\`,
\`lipid_class_only\`, \`exposure_related_metabolite\`,
\`remove_contaminant\`, and \`low_confidence_annotation\`.

## Usage

``` r
classify_annotation_confidence(data)
```

## Arguments

- data:

  A data.frame or tibble containing evidence columns.

## Value

The input data with confidence scores, final class, and decision reason
columns appended.
