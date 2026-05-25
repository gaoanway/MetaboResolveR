# Real-Case Workflow With a Public Synthetic Fixture

The private SD rhythm plasma metabolomics workbook is validated locally
only. This vignette mirrors its column structure with a small public
synthetic fixture, so the workflow can be shared without exposing study
data.

``` r

library(MetaboResolveR)
```

Read the synthetic fixture. Its columns follow the real vendor-style
schema, including `Name`, `HMDB_ID`, `KEGG_ID`, `Lipidmaps_ID`,
`PubChemID`, `m/z`, `RT (min)`, `IonMode`, and `Score`.

``` r

fixture <- system.file("extdata", "example_real_case_schema.csv", package = "MetaboResolveR")
input <- read.csv(fixture, stringsAsFactors = FALSE, check.names = FALSE)
names(input)
```

    ##  [1] "Compound_ID"           "Name"                  "ChineseName"          
    ##  [4] "IonMode"               "Formula"               "MolecularWeight"      
    ##  [7] "m/z"                   "MassError"             "Adduct"               
    ## [10] "RT (min)"              "Score"                 "Level"                
    ## [13] "Column"                "ClassI"                "ClassI (Chinese)"     
    ## [16] "ClassII"               "ClassII (Chinese)"     "ClassIII"             
    ## [19] "ClassIII (Chinese)"    "CAS"                   "HMDB_ID"              
    ## [22] "SuperClass(HMDB)"      "Class(HMDB)"           "SubClass(HMDB)"       
    ## [25] "Other_name(Kegg_name)" "KEGG_ID"               "KEGG_MapID"           
    ## [28] "Lipidmaps_ID"          "CATEGORY(Lipidmaps)"   "MAIN_CLASS(Lipidmaps)"
    ## [31] "SUB_CLASS(Lipidmaps)"  "PubChemID"             "SMILES"               
    ## [34] "InChIKey"

No explicit `column_map` is required for these aliases.

``` r

annotated <- annotate_plasma_metabolites(input)
annotated[, c(
  "Compound_ID",
  "metabolite_name",
  "hmdb_id",
  "pubchem_cid",
  "matched_reference_key",
  "plasma_evidence_sources",
  "final_annotation_class"
)]
```

    ## # A tibble: 4 × 7
    ##   Compound_ID metabolite_name hmdb_id     pubchem_cid matched_reference_key
    ##   <chr>       <chr>           <chr>       <chr>       <chr>                
    ## 1 Com_SYN_001 Glucose         HMDB0000122 5793        "hmdb_id"            
    ## 2 Com_SYN_002 Caffeine        HMDB0001847 2519        "hmdb_id"            
    ## 3 Com_SYN_003 PC(16:0/18:2)   NA          NA          ""                   
    ## 4 Com_SYN_004 Unknown feature NA          NA          ""                   
    ## # ℹ 2 more variables: plasma_evidence_sources <chr>,
    ## #   final_annotation_class <chr>

For the private workbook, the local-only scripts under
`data-raw/real_case/` split the `.xlsx` file into ten CSV chunks,
annotate each chunk, and write summary tables:

``` r

source("data-raw/real_case/split_real_case.R")
source("data-raw/real_case/run_real_case_validation.R")
```

Those outputs stay outside the public repository.
