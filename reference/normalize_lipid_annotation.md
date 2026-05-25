# Normalize lipid annotation names conservatively

Detect simple lipid-like names and normalize them to a conservative
reporting level. Molecular species such as \`Cer(18:1)\` are kept as
molecular species, while two-chain annotations such as \`PC(16:0/18:2)\`
are collapsed to sum composition. Lipid class-only names are kept out of
the core metabolite tier.

## Usage

``` r
normalize_lipid_annotation(names)
```

## Arguments

- names:

  Character vector of metabolite names.

## Value

A data.frame with original name, normalized name, lipid class, lipid
annotation level, and lipid flag.
