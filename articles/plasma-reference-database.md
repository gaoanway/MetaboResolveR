# Human Plasma Reference Database

The bundled reference database combines metabolite evidence from curated
plasma, serum, and reference-material sources. It is meant to support
annotation review, not to claim that every matched compound is
biologically endogenous in every cohort.

``` r

library(MetaboResolveR)
```

The source catalog records provenance and update notes.

``` r

catalog <- load_reference_source_catalog()
catalog[, c("source_id", "short_name", "source_kind", "evidence_role")]
```

    ##                                 source_id       short_name
    ## 1           ghosh_2024_plasma_metabolomes       Ghosh 2024
    ## 2               serum_metabolome_database Serum Metabolome
    ## 3  psychogios_2011_human_serum_metabolome  Psychogios 2011
    ## 4                            nist_srm1950    NIST SRM 1950
    ## 5                         srm1950_db_2025       SRM1950-DB
    ## 6                   plasma_benchmark_2025 Plasma Benchmark
    ## 7                               hmdb_main             HMDB
    ## 8                           husermet_2015         HUSERMET
    ## 9                             hubmet_2025           HUBMet
    ## 10                         blood_exposome   Blood Exposome
    ## 11                               drugbank         DrugBank
    ## 12                                  foodb            FooDB
    ## 13                                  chebi            ChEBI
    ## 14                              lipidmaps       LIPID MAPS
    ## 15                                 refmet           RefMet
    ##              source_kind
    ## 1     article_supplement
    ## 2      biofluid_database
    ## 3                article
    ## 4     reference_material
    ## 5     reference_database
    ## 6   article_and_resource
    ## 7    biological_database
    ## 8    article_and_archive
    ## 9    integrated_database
    ## 10     exposome_database
    ## 11         drug_database
    ## 12         food_database
    ## 13     ontology_database
    ## 14        lipid_database
    ## 15 nomenclature_standard
    ##                                                       evidence_role
    ## 1        large-cohort plasma detection and reproducibility evidence
    ## 2                    serum/plasma compendium and identifier mapping
    ## 3                            classic serum/plasma compendium source
    ## 4       gold-standard human plasma reference material and QC anchor
    ## 5                      quantitative human plasma reference database
    ## 6                                 plasma-centric benchmark evidence
    ## 7  identifier mapping, taxonomy, biofluid and concentration support
    ## 8                        supporting healthy-serum baseline evidence
    ## 9                  supporting integrative blood metabolite evidence
    ## 10                     exogenous or exposure-related blood evidence
    ## 11                                           drug labeling evidence
    ## 12                                        dietary labeling evidence
    ## 13   role or class support and endogenous/drug/xenobiotic semantics
    ## 14                            lipid normalization and class support
    ## 15                                       name normalization support

The full evidence table keeps source-specific flags and identifiers.

``` r

reference <- load_plasma_metabolite_evidence_reference()
dim(reference)
```

    ## [1] 42817    46

``` r

names(reference)
```

    ##  [1] "normalized_name"                   "metabolite_name"                  
    ##  [3] "hmdb_id"                           "pubchem_cid"                      
    ##  [5] "chebi_id"                          "kegg_id"                          
    ##  [7] "chemspider_id"                     "formula"                          
    ##  [9] "monoisotopic_molecular_weight"     "inchikey"                         
    ## [11] "smiles"                            "hmdb_status"                      
    ## [13] "direct_parent"                     "super_class"                      
    ## [15] "class"                             "sub_class"                        
    ## [17] "biospecimen_locations"             "normal_concentration_count"       
    ## [19] "normal_blood_concentration_count"  "normal_serum_concentration_count" 
    ## [21] "normal_plasma_concentration_count" "ghosh_chem_id"                    
    ## [23] "ghosh_chemical_name"               "ghosh_super_pathway"              
    ## [25] "ghosh_sub_pathway"                 "ghosh_nr_cohorts_present"         
    ## [27] "ghosh_max_missingness"             "ghosh_all5_cohorts"               
    ## [29] "ghosh_core_50pct"                  "source_serum_metabolome"          
    ## [31] "source_ghosh_2024"                 "source_srm1950_db"                
    ## [33] "srm1950_instrument_type"           "srm1950_classification"           
    ## [35] "srm1950_reference"                 "source_manual_override"           
    ## [37] "plasma_benchmark"                  "nist_srm1950"                     
    ## [39] "hmdb_biofluid"                     "serum_evidence"                   
    ## [41] "endogenous_hint"                   "lipid_class"                      
    ## [43] "source_count"                      "evidence_tier"                    
    ## [45] "pubmed_ids"                        "manual_notes"

The current evidence hierarchy is:

- Gold or core plasma evidence: curated plasma benchmark records, NIST
  SRM1950, and metabolites supported by strong cross-cohort plasma
  evidence.
- Strong supporting evidence: HMDB biofluid annotations and serum
  evidence.
- Contextual evidence: single-source or lower-reproducibility plasma
  evidence.

Identifier matching is intentionally transparent. Annotation rows can
match by HMDB/HMID, PubChem CID, ChEBI, KEGG, or normalized name, and
the output column `matched_reference_key` records which key was used.

``` r

input <- data.frame(
  metabolite_name = c(NA, NA),
  hmdb_id = c("HMDB0000122", NA),
  pubchem_cid = c(NA, "2519"),
  stringsAsFactors = FALSE
)

score_plasma_evidence(input)[, c(
  "hmdb_id",
  "pubchem_cid",
  "matched_reference_key",
  "reference_metabolite_name",
  "plasma_evidence_sources"
)]
```

    ## # A tibble: 2 × 5
    ##   hmdb_id     pubchem_cid matched_reference_key reference_metabolite_name
    ##   <chr>       <chr>       <chr>                 <chr>                    
    ## 1 HMDB0000122 NA          hmdb_id               glucose                  
    ## 2 NA          2519        pubchem_cid           Caffeine                 
    ## # ℹ 1 more variable: plasma_evidence_sources <chr>
