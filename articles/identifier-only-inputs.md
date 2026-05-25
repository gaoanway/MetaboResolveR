# Identifier-Only Inputs

Some annotation exports contain database identifiers but no reliable
compound name. `MetaboResolveR` accepts identifier-only rows and records
which key matched the reference database.

``` r

library(MetaboResolveR)
```

HMDB/HMID, PubChem CID, ChEBI, and KEGG identifiers can be supplied
without a name. Placeholder values such as `-`, `N/A`, and empty strings
are treated as missing.

``` r

input <- data.frame(
  HMID = c("HMDB0000122", "-"),
  `PubChem CID` = c(NA, "2519"),
  `ChEBI ID` = c(NA, NA),
  KEGG = c("C00031", NA),
  check.names = FALSE
)

annotated <- annotate_plasma_metabolites(input)
annotated[, c(
  "metabolite_name",
  "hmdb_id",
  "pubchem_cid",
  "kegg_id",
  "matched_reference_key",
  "reference_metabolite_name",
  "final_annotation_class"
)]
```

    ## # A tibble: 2 × 7
    ##   metabolite_name hmdb_id     pubchem_cid kegg_id matched_reference_key
    ##   <chr>           <chr>       <chr>       <chr>   <chr>                
    ## 1 NA              HMDB0000122 NA          C00031  hmdb_id              
    ## 2 NA              NA          2519        NA      pubchem_cid          
    ## # ℹ 2 more variables: reference_metabolite_name <chr>,
    ## #   final_annotation_class <chr>

If multiple identifiers are present, matching prioritizes structured
database IDs before falling back to normalized names. This makes
identifier-only inputs auditable and avoids forcing users to invent
names for uncertain annotations.
