# Export an annotation report to CSV

Write an annotated table to CSV. If the input has not yet been
annotated, \`annotate_plasma_metabolites()\` is called first. A compact
final-class summary can be written beside the report for quick review.

## Usage

``` r
export_annotation_report(data, path, include_summary = TRUE)
```

## Arguments

- data:

  An annotated data.frame or a raw input table.

- path:

  Output CSV path.

- include_summary:

  Whether to also write a final-class summary count CSV.

## Value

Invisibly returns a list of written file paths.
