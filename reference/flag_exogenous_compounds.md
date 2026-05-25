# Flag exogenous or contaminant-like compounds

Add conservative flags for compounds that are usually interpreted as
exposure-related, drug/food-derived, or technical contaminants. A
sample-to-blank ratio below 3 also triggers a contaminant flag when that
column is supplied.

## Usage

``` r
flag_exogenous_compounds(data, column_map = NULL)
```

## Arguments

- data:

  A data.frame or tibble with metabolite annotation information.

- column_map:

  Optional named list that maps canonical field names to input columns.

## Value

The input data with exogenous category, source, flag, contaminant flag,
and penalty columns appended.
