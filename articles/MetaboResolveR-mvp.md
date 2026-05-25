# MetaboResolveR Overview

`MetaboResolveR` resolves post-identification untargeted human plasma
metabolomics tables into evidence-scored annotation outputs. It is
designed for reviewing LC-MS metabolite annotation exports, not for raw
peak detection.

``` r

library(MetaboResolveR)
```

The main entry point is
[`annotate_plasma_metabolites()`](https://gaoanway.github.io/MetaboResolveR/reference/annotate_plasma_metabolites.md).

``` r

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

    ## # A tibble: 3 × 3
    ##   metabolite_name matched_reference_key final_annotation_class     
    ##   <chr>           <chr>                 <chr>                      
    ## 1 Glucose         "hmdb_id"             probable_plasma_metabolite 
    ## 2 Caffeine        "hmdb_id"             exposure_related_metabolite
    ## 3 Unknown feature ""                    low_confidence_annotation

Use
[`export_annotation_report()`](https://gaoanway.github.io/MetaboResolveR/reference/export_annotation_report.md)
when you want a CSV annotation table plus a compact final-class summary.
