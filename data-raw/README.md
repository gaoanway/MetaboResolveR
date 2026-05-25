# Raw Data Rebuild Notes

This directory contains scripts and public source snapshots used to rebuild the
bundled plasma reference tables.

`serum_metabolites.zip` is not committed because it is larger than GitHub's
ordinary single-file limit. To rebuild the reference database, download the
current Serum Metabolome/HMDB serum metabolite archive into this directory as:

```text
data-raw/serum_metabolites.zip
```

The private real-case validation workflow lives under `data-raw/real_case/`.
That directory is local-only and must not be committed.

Known source-name corrections are tracked in
`data-raw/manual_source_name_corrections.csv` and applied during reference-table
rebuilds.
