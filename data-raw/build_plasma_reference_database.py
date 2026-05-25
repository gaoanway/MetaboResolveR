"""Build bundled human plasma/serum metabolite reference tables.

Inputs are primary or near-primary public data files saved under data-raw:
- serum_metabolites.zip from Serum Metabolome / HMDB
- ghosh_2024_supplementary_table_2.xlsx from Scientific Reports 2024
- srm1950_data_2025.csv from SRM1950-DB
- manual_curated_reference_overrides.csv for small package-scaffold seeds

Outputs are CSV files under data-raw/processed and inst/extdata.
"""

from __future__ import annotations

import csv
import html
import re
import zipfile
from pathlib import Path
from xml.etree import ElementTree as ET

import openpyxl


ROOT = Path(__file__).resolve().parents[1]
DATA_RAW = ROOT / "data-raw"
PROCESSED = DATA_RAW / "processed"
EXTDATA = ROOT / "inst" / "extdata"

SERUM_ZIP = DATA_RAW / "serum_metabolites.zip"
GHOSH_XLSX = DATA_RAW / "ghosh_2024_supplementary_table_2.xlsx"
SRM1950_CSV = DATA_RAW / "srm1950_data_2025.csv"
OVERRIDES_CSV = DATA_RAW / "manual_curated_reference_overrides.csv"
SOURCE_NAME_CORRECTIONS_CSV = DATA_RAW / "manual_source_name_corrections.csv"

SERUM_PARSED_CSV = PROCESSED / "serum_metabolome_hmdb_parsed.csv"
GHOSH_PARSED_CSV = PROCESSED / "ghosh_2024_plasma_metabolomes.csv"
SRM1950_PARSED_CSV = PROCESSED / "srm1950_db_2025_reference.csv"
EVIDENCE_CSV = EXTDATA / "plasma_metabolite_evidence_reference.csv"
CORE_CSV = EXTDATA / "plasma_core_reference.csv"
SOURCE_CATALOG_CSV = EXTDATA / "reference_source_catalog.csv"
DATA_DICTIONARY_CSV = EXTDATA / "plasma_reference_data_dictionary.csv"


def text_or_empty(parent: ET.Element, child_tag: str) -> str:
    child = parent.find(f"{{*}}{child_tag}")
    if child is None or child.text is None:
        return ""
    return html.unescape(child.text).strip()


def all_text(parent: ET.Element, path: str, leaf_tag: str) -> list[str]:
    node = parent.find(path)
    if node is None:
        return []
    out: list[str] = []
    for child in node.findall(f".//{{*}}{leaf_tag}"):
        if child.text and child.text.strip():
            out.append(html.unescape(child.text).strip())
    return out


def normalize_name(value: object) -> str:
    if value is None:
        return ""
    text = html.unescape(str(value)).strip().lower()
    text = text.replace("\u00a0", " ")
    text = text.replace("\t", " ")
    text = re.sub(r"\s+", " ", text)
    text = re.sub(r"\*+$", "", text).strip()
    text = text.replace(" ;", ";")
    return text


def normalize_hmdb_id(value: object) -> str:
    text = "" if value is None else str(value).strip().upper()
    return "" if text in {"", "NA", "NAN", "NULL"} else text


def normalize_pubchem_cid(value: object) -> str:
    text = "" if value is None else str(value).strip()
    text = re.sub(r"^CID[:\s]*", "", text, flags=re.IGNORECASE)
    text = re.sub(r"\.0$", "", text)
    return "" if text.upper() in {"", "NA", "NAN", "NULL"} else text


def normalize_chebi_id(value: object) -> str:
    text = "" if value is None else str(value).strip().upper()
    text = text.replace("CHEBI:", "")
    text = re.sub(r"\.0$", "", text)
    return "" if text in {"", "NA", "NAN", "NULL"} else text


def clean_ghosh_name(value: object) -> str:
    text = "" if value is None else str(value).strip()
    text = text.replace("\t", " ")
    text = re.sub(r"\s+", " ", text)
    return text


def bool_text(value: bool) -> str:
    return "TRUE" if value else "FALSE"


def parse_float(value: object) -> float | None:
    if value is None:
        return None
    text = str(value).strip()
    if text == "" or text.upper() == "NA":
        return None
    try:
        return float(text)
    except ValueError:
        return None


def parse_serum_metabolome() -> list[dict[str, str]]:
    PROCESSED.mkdir(parents=True, exist_ok=True)
    records: list[dict[str, str]] = []
    with zipfile.ZipFile(SERUM_ZIP) as zf:
        with zf.open("serum_metabolites.xml") as fh:
            context = ET.iterparse(fh, events=("end",))
            for _, elem in context:
                if elem.tag.endswith("metabolite"):
                    accession = text_or_empty(elem, "accession")
                    name = text_or_empty(elem, "name")
                    biospecimens = all_text(
                        elem,
                        ".//{*}biological_properties/{*}biospecimen_locations",
                        "biospecimen",
                    )
                    normal_concs = elem.findall(".//{*}normal_concentrations/{*}concentration")
                    normal_biospecimens = []
                    normal_blood_count = 0
                    normal_serum_count = 0
                    normal_plasma_count = 0
                    pubmed_ids: list[str] = []
                    for conc in normal_concs:
                        biospecimen = text_or_empty(conc, "biospecimen")
                        if biospecimen:
                            normal_biospecimens.append(biospecimen)
                        biospecimen_lower = biospecimen.lower()
                        if "blood" in biospecimen_lower:
                            normal_blood_count += 1
                        if "serum" in biospecimen_lower:
                            normal_serum_count += 1
                        if "plasma" in biospecimen_lower:
                            normal_plasma_count += 1
                        for pmid in conc.findall(".//{*}pubmed_id"):
                            if pmid.text and pmid.text.strip():
                                pubmed_ids.append(pmid.text.strip())

                    general_pubmed_ids = [
                        x
                        for x in all_text(elem, ".//{*}general_references", "pubmed_id")
                        if x
                    ]
                    combined_pubmed_ids = []
                    seen_pmids = set()
                    for pmid in pubmed_ids + general_pubmed_ids:
                        if pmid not in seen_pmids:
                            combined_pubmed_ids.append(pmid)
                            seen_pmids.add(pmid)

                    biospecimen_set = sorted(set(biospecimens), key=str.lower)
                    concentration_biospecimen_set = sorted(
                        set(normal_biospecimens), key=str.lower
                    )
                    biospecimen_lower_joined = "; ".join(biospecimen_set).lower()
                    has_blood = "blood" in biospecimen_lower_joined
                    has_serum = "serum" in biospecimen_lower_joined
                    has_plasma = "plasma" in biospecimen_lower_joined

                    taxonomy = elem.find(".//{*}taxonomy")
                    if taxonomy is None:
                        taxonomy = elem

                    records.append(
                        {
                            "normalized_name": normalize_name(name),
                            "metabolite_name": name,
                            "hmdb_id": normalize_hmdb_id(accession),
                            "pubchem_cid": normalize_pubchem_cid(
                                text_or_empty(elem, "pubchem_compound_id")
                            ),
                            "chebi_id": normalize_chebi_id(text_or_empty(elem, "chebi_id")),
                            "kegg_id": text_or_empty(elem, "kegg_id"),
                            "chemspider_id": text_or_empty(elem, "chemspider_id"),
                            "status": text_or_empty(elem, "status"),
                            "formula": text_or_empty(elem, "chemical_formula"),
                            "monoisotopic_molecular_weight": text_or_empty(
                                elem, "monisotopic_molecular_weight"
                            ),
                            "average_molecular_weight": text_or_empty(
                                elem, "average_molecular_weight"
                            ),
                            "inchikey": text_or_empty(elem, "inchikey"),
                            "smiles": text_or_empty(elem, "smiles"),
                            "direct_parent": text_or_empty(taxonomy, "direct_parent"),
                            "super_class": text_or_empty(taxonomy, "super_class"),
                            "class": text_or_empty(taxonomy, "class"),
                            "sub_class": text_or_empty(taxonomy, "sub_class"),
                            "biospecimen_locations": "; ".join(biospecimen_set),
                            "serum_metabolome_has_blood": bool_text(has_blood),
                            "serum_metabolome_has_serum": bool_text(has_serum),
                            "serum_metabolome_has_plasma": bool_text(has_plasma),
                            "normal_concentration_count": str(len(normal_concs)),
                            "normal_blood_concentration_count": str(normal_blood_count),
                            "normal_serum_concentration_count": str(normal_serum_count),
                            "normal_plasma_concentration_count": str(normal_plasma_count),
                            "normal_concentration_biospecimens": "; ".join(
                                concentration_biospecimen_set
                            ),
                            "pubmed_ids": "; ".join(combined_pubmed_ids[:30]),
                            "source_serum_metabolome": "TRUE",
                        }
                    )
                    elem.clear()
    write_csv(SERUM_PARSED_CSV, records)
    return records


def parse_ghosh_workbook() -> list[dict[str, str]]:
    wb = openpyxl.load_workbook(GHOSH_XLSX, read_only=True, data_only=True)
    ws = wb["Supplementary Table 1"]
    rows = ws.iter_rows(values_only=True)
    header = [str(x) if x is not None else "" for x in next(rows)]
    records: list[dict[str, str]] = []
    for row in rows:
        data = dict(zip(header, row))
        name = clean_ghosh_name(data.get("CHEMICAL_NAME"))
        if not name:
            continue
        max_missing = parse_float(data.get("max_missingness"))
        nr_cohorts = int(parse_float(data.get("nr_of_cohorts_present")) or 0)
        all5 = nr_cohorts == 5
        core_50pct = all5 and max_missing is not None and max_missing <= 50
        records.append(
            {
                "normalized_name": normalize_name(name),
                "ghosh_chemical_name": name,
                "ghosh_chem_id": str(data.get("CHEM_ID") or ""),
                "ghosh_super_pathway": str(data.get("SUPER_PATHWAY") or ""),
                "ghosh_sub_pathway": str(data.get("SUB_PATHWAY") or ""),
                "ghosh_nr_cohorts_present": str(nr_cohorts),
                "ghosh_max_missingness": "" if max_missing is None else str(max_missing),
                "ghosh_percent_missing_MDCS": str(data.get("percent_missing_MDCS") or ""),
                "ghosh_percent_missing_PIVUS": str(data.get("percent_missing_PIVUS") or ""),
                "ghosh_percent_missing_POEM": str(data.get("percent_missing_POEM") or ""),
                "ghosh_percent_missing_SCAPIS_M": str(
                    data.get("percent_missing_SCAPIS-M") or ""
                ),
                "ghosh_percent_missing_SCAPIS_U": str(
                    data.get("percent_missing_SCAPIS-U") or ""
                ),
                "ghosh_all5_cohorts": bool_text(all5),
                "ghosh_core_50pct": bool_text(core_50pct),
                "source_ghosh_2024": "TRUE",
            }
        )
    wb.close()
    write_csv(GHOSH_PARSED_CSV, records)
    return records


def parse_srm1950_db() -> list[dict[str, str]]:
    if not SRM1950_CSV.exists():
        return []
    records: list[dict[str, str]] = []
    corrections = read_source_name_corrections("srm1950_db_2025")
    with SRM1950_CSV.open(newline="", encoding="utf-8-sig") as fh:
        for row in csv.DictReader(fh):
            name = row.get("metabolite_name", "").strip()
            hmdb_id = normalize_hmdb_id(row.get("hmdb_id"))
            name = apply_source_name_corrections(name, hmdb_id, corrections)
            if not name and not hmdb_id:
                continue
            records.append(
                {
                    "normalized_name": normalize_name(name),
                    "metabolite_name": name,
                    "hmdb_id": hmdb_id,
                    "smiles": row.get("smiles", "").strip(),
                    "average_molecular_weight": row.get("average_mass", "").strip(),
                    "monoisotopic_molecular_weight": row.get("mono_mass", "").strip(),
                    "srm1950_instrument_type": row.get("instrument_type", "").strip(),
                    "srm1950_classification": row.get("classification", "").strip(),
                    "srm1950_reference": row.get("reference", "").strip(),
                    "source_srm1950_db": "TRUE",
                    "nist_srm1950": "TRUE",
                    "serum_evidence": "TRUE",
                    "hmdb_biofluid": "TRUE",
                    "endogenous_hint": "TRUE",
                }
            )
    write_csv(SRM1950_PARSED_CSV, records)
    return records


def read_csv_records(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


def read_source_name_corrections(source_id: str) -> list[dict[str, str]]:
    if not SOURCE_NAME_CORRECTIONS_CSV.exists():
        return []

    corrections = []
    with SOURCE_NAME_CORRECTIONS_CSV.open(newline="", encoding="utf-8") as fh:
        for row in csv.DictReader(fh):
            if row.get("source_id", "").strip() != source_id:
                continue
            corrections.append(
                {
                    "hmdb_id": normalize_hmdb_id(row.get("hmdb_id")),
                    "original_name": row.get("original_name", "").strip(),
                    "corrected_name": row.get("corrected_name", "").strip(),
                }
            )
    return corrections


def apply_source_name_corrections(
    name: str,
    hmdb_id: str,
    corrections: list[dict[str, str]],
) -> str:
    for correction in corrections:
        same_hmdb = correction["hmdb_id"] == hmdb_id
        same_name = correction["original_name"] in {"", name}
        if same_hmdb and same_name and correction["corrected_name"]:
            return correction["corrected_name"]
    return name


def write_csv(path: Path, rows: list[dict[str, str]], fieldnames: list[str] | None = None) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if fieldnames is None:
        ordered: list[str] = []
        for row in rows:
            for key in row:
                if key not in ordered:
                    ordered.append(key)
        fieldnames = ordered
    with path.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def first_nonempty(*values: str) -> str:
    for value in values:
        if value is not None and str(value).strip():
            return str(value).strip()
    return ""


def merge_records(
    serum_records: list[dict[str, str]],
    ghosh_records: list[dict[str, str]],
    srm1950_records: list[dict[str, str]],
    override_records: list[dict[str, str]],
) -> tuple[list[dict[str, str]], list[dict[str, str]]]:
    by_name: dict[str, dict[str, str]] = {}

    def ensure(name: str) -> dict[str, str]:
        if name not in by_name:
            by_name[name] = {"normalized_name": name}
        return by_name[name]

    for row in serum_records:
        name = row["normalized_name"]
        if not name:
            continue
        dest = ensure(name)
        dest.update(row)

    for row in ghosh_records:
        name = row["normalized_name"]
        if not name:
            continue
        dest = ensure(name)
        for key, value in row.items():
            if key == "normalized_name":
                continue
            dest[key] = value

    for row in srm1950_records:
        name = row["normalized_name"]
        if not name:
            continue
        dest = ensure(name)
        for key, value in row.items():
            if key == "normalized_name":
                continue
            if key in {
                "nist_srm1950",
                "hmdb_biofluid",
                "serum_evidence",
                "endogenous_hint",
                "source_srm1950_db",
            }:
                if str(value).strip().upper() == "TRUE":
                    dest[key] = "TRUE"
                elif key not in dest:
                    dest[key] = "FALSE"
            elif value and not dest.get(key):
                dest[key] = value

    for row in override_records:
        name = normalize_name(row.get("normalized_name"))
        if not name:
            continue
        dest = ensure(name)
        for key, value in row.items():
            if key == "normalized_name":
                continue
            if key in {
                "plasma_benchmark",
                "nist_srm1950",
                "hmdb_biofluid",
                "serum_evidence",
                "endogenous_hint",
            }:
                if str(value).strip().upper() == "TRUE":
                    dest[key] = "TRUE"
                elif key not in dest:
                    dest[key] = "FALSE"
            elif value and not dest.get(key):
                dest[key] = value

    evidence_rows: list[dict[str, str]] = []
    core_rows: list[dict[str, str]] = []
    for name in sorted(by_name):
        row = by_name[name]
        serum_hit = row.get("source_serum_metabolome") == "TRUE"
        ghosh_hit = row.get("source_ghosh_2024") == "TRUE"
        ghosh_all5 = row.get("ghosh_all5_cohorts") == "TRUE"
        ghosh_core = row.get("ghosh_core_50pct") == "TRUE"
        srm1950_hit = row.get("source_srm1950_db") == "TRUE"
        normal_biofluid_count = sum(
            int(row.get(field, "0") or 0)
            for field in [
                "normal_blood_concentration_count",
                "normal_serum_concentration_count",
                "normal_plasma_concentration_count",
            ]
        )
        serum_status_evidence = row.get("status") in {"detected", "quantified"}
        serum_evidence = (
            (serum_hit and (serum_status_evidence or normal_biofluid_count > 0))
            or row.get("serum_evidence") == "TRUE"
        )
        hmdb_biofluid = serum_evidence or row.get("hmdb_biofluid") == "TRUE"
        nist_srm1950 = row.get("nist_srm1950") == "TRUE"
        plasma_benchmark = row.get("plasma_benchmark") == "TRUE"
        ghosh_pathway = row.get("ghosh_super_pathway", "")
        ghosh_endogenous_hint = ghosh_hit and ghosh_pathway not in {
            "Xenobiotics",
            "Partially Characterized Molecules",
        }
        endogenous_hint = (
            row.get("endogenous_hint") == "TRUE"
            or ghosh_endogenous_hint
            or (serum_evidence and row.get("status") == "quantified")
        )

        source_count = sum(
            [
                serum_hit,
                ghosh_hit,
                srm1950_hit,
                nist_srm1950,
                plasma_benchmark,
            ]
        )
        if srm1950_hit or ghosh_core or (nist_srm1950 and serum_evidence) or (plasma_benchmark and serum_evidence):
            evidence_tier = "Tier 1_gold_or_core_plasma"
        elif ghosh_all5 or (serum_evidence and row.get("status") == "quantified"):
            evidence_tier = "Tier 2_probable_plasma"
        elif serum_evidence:
            evidence_tier = "Tier 3_serum_plasma_compendium"
        elif ghosh_hit:
            evidence_tier = "Tier 3_plasma_detected"
        else:
            evidence_tier = "Tier 4_expected_or_supporting"

        metabolite_name = first_nonempty(
            row.get("metabolite_name", ""),
            row.get("ghosh_chemical_name", ""),
            name,
        )
        lipid_class = first_nonempty(row.get("lipid_class", ""), row.get("ghosh_super_pathway", ""))
        if lipid_class.lower() != "lipid" and not lipid_class.upper() in {"PC", "LPC"}:
            lipid_class = row.get("lipid_class", "")

        evidence_row = {
            "normalized_name": name,
            "metabolite_name": metabolite_name,
            "hmdb_id": row.get("hmdb_id", ""),
            "pubchem_cid": row.get("pubchem_cid", ""),
            "chebi_id": row.get("chebi_id", ""),
            "kegg_id": row.get("kegg_id", ""),
            "chemspider_id": row.get("chemspider_id", ""),
            "formula": row.get("formula", ""),
            "monoisotopic_molecular_weight": row.get(
                "monoisotopic_molecular_weight", ""
            ),
            "inchikey": row.get("inchikey", ""),
            "smiles": row.get("smiles", ""),
            "hmdb_status": row.get("status", ""),
            "direct_parent": row.get("direct_parent", ""),
            "super_class": row.get("super_class", ""),
            "class": row.get("class", ""),
            "sub_class": row.get("sub_class", ""),
            "biospecimen_locations": row.get("biospecimen_locations", ""),
            "normal_concentration_count": row.get("normal_concentration_count", ""),
            "normal_blood_concentration_count": row.get(
                "normal_blood_concentration_count", ""
            ),
            "normal_serum_concentration_count": row.get(
                "normal_serum_concentration_count", ""
            ),
            "normal_plasma_concentration_count": row.get(
                "normal_plasma_concentration_count", ""
            ),
            "ghosh_chem_id": row.get("ghosh_chem_id", ""),
            "ghosh_chemical_name": row.get("ghosh_chemical_name", ""),
            "ghosh_super_pathway": row.get("ghosh_super_pathway", ""),
            "ghosh_sub_pathway": row.get("ghosh_sub_pathway", ""),
            "ghosh_nr_cohorts_present": row.get("ghosh_nr_cohorts_present", ""),
            "ghosh_max_missingness": row.get("ghosh_max_missingness", ""),
            "ghosh_all5_cohorts": bool_text(ghosh_all5),
            "ghosh_core_50pct": bool_text(ghosh_core),
            "source_serum_metabolome": bool_text(serum_hit),
            "source_ghosh_2024": bool_text(ghosh_hit),
            "source_srm1950_db": bool_text(srm1950_hit),
            "srm1950_instrument_type": row.get("srm1950_instrument_type", ""),
            "srm1950_classification": row.get("srm1950_classification", ""),
            "srm1950_reference": row.get("srm1950_reference", ""),
            "source_manual_override": bool_text(bool(row.get("manual_notes", ""))),
            "plasma_benchmark": bool_text(plasma_benchmark),
            "nist_srm1950": bool_text(nist_srm1950),
            "hmdb_biofluid": bool_text(hmdb_biofluid),
            "serum_evidence": bool_text(serum_evidence),
            "endogenous_hint": bool_text(endogenous_hint),
            "lipid_class": lipid_class,
            "source_count": str(source_count),
            "evidence_tier": evidence_tier,
            "pubmed_ids": row.get("pubmed_ids", ""),
            "manual_notes": row.get("manual_notes", ""),
        }
        evidence_rows.append(evidence_row)
        core_rows.append(
            {
                "normalized_name": name,
                "metabolite_name": metabolite_name,
                "hmdb_id": evidence_row["hmdb_id"],
                "pubchem_cid": evidence_row["pubchem_cid"],
                "chebi_id": evidence_row["chebi_id"],
                "kegg_id": evidence_row["kegg_id"],
                "plasma_benchmark": bool_text(plasma_benchmark),
                "nist_srm1950": bool_text(nist_srm1950),
                "hmdb_biofluid": bool_text(hmdb_biofluid),
                "serum_evidence": bool_text(serum_evidence),
                "endogenous_hint": evidence_row["endogenous_hint"],
                "lipid_class": lipid_class,
                "ghosh_2024_plasma": bool_text(ghosh_hit),
                "ghosh_2024_all5_cohorts": bool_text(ghosh_all5),
                "ghosh_2024_core_50pct": bool_text(ghosh_core),
                "serum_metabolome": bool_text(serum_hit),
                "srm1950_db": bool_text(srm1950_hit),
                "source_count": str(source_count),
                "evidence_tier": evidence_tier,
            }
        )
    return evidence_rows, core_rows


def build_source_catalog() -> list[dict[str, str]]:
    return [
        {
            "source_id": "ghosh_2024_plasma_metabolomes",
            "source_kind": "article_supplement",
            "short_name": "Ghosh 2024",
            "title_or_resource": "Analysis of plasma metabolomes from 11,309 individuals",
            "resource_scope": "Untargeted LC-MS human fasting plasma metabolites across five cohorts",
            "evidence_role": "large-cohort plasma detection and reproducibility evidence",
            "primary_url": "https://www.nature.com/articles/s41598-024-59388-7",
            "citation_text": "Ghosh et al. Scientific Reports 2024; supplementary table of 1,629 plasma metabolites.",
            "version_or_release": "2024",
            "update_strategy": "manual_download_supplement",
            "notes": "Imported Supplementary Table 1; core flags are based on all five cohorts and max missingness <=50%.",
        },
        {
            "source_id": "serum_metabolome_database",
            "source_kind": "biofluid_database",
            "short_name": "Serum Metabolome",
            "title_or_resource": "The Serum Metabolome Database / HMDB serum metabolite XML",
            "resource_scope": "Human serum and blood small molecules with HMDB identifiers and concentration literature",
            "evidence_role": "serum/plasma compendium and identifier mapping",
            "primary_url": "https://www.serummetabolome.ca/downloads",
            "citation_text": "Psychogios et al. The Human Serum Metabolome. PLoS ONE 2011; Serum Metabolome Database downloads.",
            "version_or_release": "HMDB 5.0 XML download",
            "update_strategy": "manual_download_current_zip",
            "notes": "Imported serum_metabolites.zip XML; serum evidence is treated as blood-adjacent support, not alone as MSI level 1.",
        },
        {
            "source_id": "psychogios_2011_human_serum_metabolome",
            "source_kind": "article",
            "short_name": "Psychogios 2011",
            "title_or_resource": "The Human Serum Metabolome",
            "resource_scope": "Confirmed or highly probable human serum/plasma compounds",
            "evidence_role": "classic serum/plasma compendium source",
            "primary_url": "https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0016957",
            "citation_text": "Psychogios N et al. PLoS ONE 2011; reported 4,229 confirmed or highly probable serum/plasma compounds.",
            "version_or_release": "2011",
            "update_strategy": "covered_by_serum_metabolome_database",
            "notes": "Use as conceptual/citation basis for the Serum Metabolome compendium.",
        },
        {
            "source_id": "nist_srm1950",
            "source_kind": "reference_material",
            "short_name": "NIST SRM 1950",
            "title_or_resource": "Metabolites in Human Plasma Standard Reference Material 1950",
            "resource_scope": "NIST human plasma QC/reference material",
            "evidence_role": "gold-standard human plasma reference material and QC anchor",
            "primary_url": "https://www.nist.gov/programs-projects/metabolomics-quality-assurance-and-quality-control-materials-metqual-program",
            "citation_text": "NIST SRM 1950 and associated metabolomics quality assurance publications.",
            "version_or_release": "rolling",
            "update_strategy": "manual_curated_update",
            "notes": "Kept as highest-confidence source category; full compound list is not imported by this build script.",
        },
        {
            "source_id": "srm1950_db_2025",
            "source_kind": "reference_database",
            "short_name": "SRM1950-DB",
            "title_or_resource": "SRM1950-DB metabolite concentration reference database",
            "resource_scope": "High-confidence metabolites and metabolite species in NIST SRM 1950",
            "evidence_role": "quantitative human plasma reference database",
            "primary_url": "https://srm1950-data.wishartlab.com/",
            "citation_text": "Mandal et al. 2025 SRM1950-DB resource.",
            "version_or_release": "1.0",
            "update_strategy": "manual_download_csv",
            "notes": "Imported srm1950-data.csv as a gold/reference-material evidence source.",
        },
        {
            "source_id": "plasma_benchmark_2025",
            "source_kind": "article_and_resource",
            "short_name": "Plasma Benchmark",
            "title_or_resource": "Plasma Benchmark human plasma LC-MS benchmark resource",
            "resource_scope": "Human plasma metabolites and lipids robustly detectable by LC-MS",
            "evidence_role": "plasma-centric benchmark evidence",
            "primary_url": "https://plasmabenchmark.utu.fi/",
            "citation_text": "Plasma Benchmark resource and associated 2025 article on robustly detectable human plasma metabolites and lipids.",
            "version_or_release": "2025",
            "update_strategy": "manual_import_when_accessible",
            "notes": "Cataloged as a key plasma benchmark source; only package seed overrides are currently marked.",
        },
        {
            "source_id": "hmdb_main",
            "source_kind": "biological_database",
            "short_name": "HMDB",
            "title_or_resource": "Human Metabolome Database",
            "resource_scope": "Human metabolites and biofluids",
            "evidence_role": "identifier mapping, taxonomy, biofluid and concentration support",
            "primary_url": "https://hmdb.ca/",
            "citation_text": "Wishart DS et al. HMDB 5.0 and related HMDB releases.",
            "version_or_release": "5.0+",
            "update_strategy": "manual_download_current_zip",
            "notes": "Used through the Serum Metabolome XML subset in this build.",
        },
        {
            "source_id": "husermet_2015",
            "source_kind": "article_and_archive",
            "short_name": "HUSERMET",
            "title_or_resource": "HUSERMET: human serum metabolome study in 1,200 healthy adults",
            "resource_scope": "Untargeted GC-MS and UPLC-MS human serum profiles",
            "evidence_role": "supporting healthy-serum baseline evidence",
            "primary_url": "https://link.springer.com/article/10.1007/s11306-014-0707-1",
            "citation_text": "Dunn et al. Metabolomics 2015; HUSERMET study and MetaboLights MTBLS97.",
            "version_or_release": "2015",
            "update_strategy": "manual_follow_up",
            "notes": "Cataloged for future import; not currently parsed into the bundled table.",
        },
        {
            "source_id": "hubmet_2025",
            "source_kind": "integrated_database",
            "short_name": "HUBMet",
            "title_or_resource": "HUBMet human blood metabolite integrated database",
            "resource_scope": "Human blood metabolites integrated from literature and databases",
            "evidence_role": "supporting integrative blood metabolite evidence",
            "primary_url": "https://link.springer.com/article/10.1186/s13059-025-03922-x",
            "citation_text": "HUBMet Genome Biology 2025 integrated human blood metabolite resource.",
            "version_or_release": "2025",
            "update_strategy": "manual_follow_up",
            "notes": "Use as a secondary integrative source after tracing original evidence.",
        },
        {
            "source_id": "blood_exposome",
            "source_kind": "exposome_database",
            "short_name": "Blood Exposome",
            "title_or_resource": "Blood Exposome Database",
            "resource_scope": "Blood chemicals including endogenous and exogenous compounds",
            "evidence_role": "exogenous or exposure-related blood evidence",
            "primary_url": "https://bloodexposome.org/",
            "citation_text": "Barupal DK and Fiehn O. Generating the Blood Exposome Database. Environ Health Perspect. 2019.",
            "version_or_release": "2019+",
            "update_strategy": "manual_curated_update",
            "notes": "Use to flag compounds known in blood that may still be exogenous.",
        },
        {
            "source_id": "drugbank",
            "source_kind": "drug_database",
            "short_name": "DrugBank",
            "title_or_resource": "DrugBank database",
            "resource_scope": "Drugs and drug metabolites",
            "evidence_role": "drug labeling evidence",
            "primary_url": "https://go.drugbank.com/",
            "citation_text": "DrugBank database releases.",
            "version_or_release": "current",
            "update_strategy": "manual_curated_update",
            "notes": "Use to flag pharmaceuticals and drug-like molecules.",
        },
        {
            "source_id": "foodb",
            "source_kind": "food_database",
            "short_name": "FooDB",
            "title_or_resource": "FooDB food composition database",
            "resource_scope": "Food compounds and food-derived chemicals",
            "evidence_role": "dietary labeling evidence",
            "primary_url": "https://foodb.ca/",
            "citation_text": "FooDB database releases from the Wishart lab.",
            "version_or_release": "current",
            "update_strategy": "manual_curated_update",
            "notes": "Use to flag food-derived and dietary compounds.",
        },
        {
            "source_id": "chebi",
            "source_kind": "ontology_database",
            "short_name": "ChEBI",
            "title_or_resource": "Chemical Entities of Biological Interest ontology",
            "resource_scope": "Chemical ontology and roles",
            "evidence_role": "role or class support and endogenous/drug/xenobiotic semantics",
            "primary_url": "https://www.ebi.ac.uk/chebi/",
            "citation_text": "ChEBI ontology releases.",
            "version_or_release": "current",
            "update_strategy": "manual_curated_update",
            "notes": "Use for chemical roles such as metabolite, drug, xenobiotic, or natural product.",
        },
        {
            "source_id": "lipidmaps",
            "source_kind": "lipid_database",
            "short_name": "LIPID MAPS",
            "title_or_resource": "LIPID MAPS structure and classification resources",
            "resource_scope": "Lipid structures, classes, and nomenclature",
            "evidence_role": "lipid normalization and class support",
            "primary_url": "https://www.lipidmaps.org/",
            "citation_text": "LIPID MAPS consortium resources and database releases.",
            "version_or_release": "current",
            "update_strategy": "manual_curated_update",
            "notes": "Use for conservative lipid class handling and identifiers.",
        },
        {
            "source_id": "refmet",
            "source_kind": "nomenclature_standard",
            "short_name": "RefMet",
            "title_or_resource": "RefMet metabolite nomenclature standard",
            "resource_scope": "Metabolite naming and harmonization",
            "evidence_role": "name normalization support",
            "primary_url": "https://www.metabolomicsworkbench.org/databases/refmet/",
            "citation_text": "RefMet naming standard distributed through Metabolomics Workbench.",
            "version_or_release": "current",
            "update_strategy": "manual_curated_update",
            "notes": "Use to harmonize metabolite names, especially lipid reporting.",
        },
    ]


def build_data_dictionary() -> list[dict[str, str]]:
    return [
        {"field": "normalized_name", "meaning": "Lowercase normalized lookup key used for name joins."},
        {"field": "metabolite_name", "meaning": "Preferred display name from HMDB/Serum Metabolome or Ghosh 2024."},
        {"field": "hmdb_id", "meaning": "HMDB accession when available from Serum Metabolome XML."},
        {"field": "pubchem_cid", "meaning": "PubChem Compound ID from HMDB/Serum Metabolome when available."},
        {"field": "chebi_id", "meaning": "ChEBI identifier from HMDB/Serum Metabolome when available."},
        {"field": "kegg_id", "meaning": "KEGG compound identifier from HMDB/Serum Metabolome when available."},
        {"field": "formula", "meaning": "Chemical formula from HMDB when available."},
        {"field": "monoisotopic_molecular_weight", "meaning": "Monoisotopic molecular weight from HMDB when available."},
        {"field": "inchikey", "meaning": "InChIKey from HMDB when available."},
        {"field": "biospecimen_locations", "meaning": "HMDB/Serum Metabolome biospecimen locations."},
        {"field": "normal_*_concentration_count", "meaning": "Number of normal concentration entries by biospecimen type."},
        {"field": "ghosh_*", "meaning": "Fields extracted from Ghosh 2024 Supplementary Table 1."},
        {"field": "srm1950_*", "meaning": "Fields extracted from SRM1950-DB 2025 CSV."},
        {"field": "ghosh_all5_cohorts", "meaning": "TRUE if the metabolite was present in all five Ghosh 2024 cohorts."},
        {"field": "ghosh_core_50pct", "meaning": "TRUE if present in all five cohorts and max missingness <=50%."},
        {"field": "source_*", "meaning": "Boolean source-hit flags for provenance."},
        {"field": "plasma_benchmark", "meaning": "Manual or imported Plasma Benchmark evidence flag; currently only seed overrides are marked."},
        {"field": "nist_srm1950", "meaning": "Manual or imported NIST SRM 1950 evidence flag; currently only seed overrides are marked."},
        {"field": "hmdb_biofluid", "meaning": "TRUE if Serum Metabolome/HMDB biofluid support is available."},
        {"field": "serum_evidence", "meaning": "TRUE if serum/blood compendium support is available."},
        {"field": "source_count", "meaning": "Number of imported/curated evidence sources supporting the row."},
        {"field": "evidence_tier", "meaning": "Operational plasma-reference confidence tier used by the package."},
    ]


def main() -> None:
    if not SERUM_ZIP.exists():
        raise FileNotFoundError(f"Missing {SERUM_ZIP}")
    if not GHOSH_XLSX.exists():
        raise FileNotFoundError(f"Missing {GHOSH_XLSX}")

    serum_records = parse_serum_metabolome()
    ghosh_records = parse_ghosh_workbook()
    srm1950_records = parse_srm1950_db()
    override_records = read_csv_records(OVERRIDES_CSV)
    evidence_rows, core_rows = merge_records(
        serum_records,
        ghosh_records,
        srm1950_records,
        override_records,
    )

    write_csv(EVIDENCE_CSV, evidence_rows)
    write_csv(CORE_CSV, core_rows)
    write_csv(SOURCE_CATALOG_CSV, build_source_catalog())
    write_csv(DATA_DICTIONARY_CSV, build_data_dictionary())

    summary = {
        "serum_metabolome_rows": len(serum_records),
        "ghosh_2024_rows": len(ghosh_records),
        "srm1950_db_rows": len(srm1950_records),
        "merged_evidence_rows": len(evidence_rows),
        "ghosh_all5_rows": sum(r["ghosh_2024_all5_cohorts"] == "TRUE" for r in core_rows),
        "ghosh_core_50pct_rows": sum(r["ghosh_2024_core_50pct"] == "TRUE" for r in core_rows),
        "serum_metabolome_rows_retained": sum(r["serum_metabolome"] == "TRUE" for r in core_rows),
        "serum_evidence_rows_scored": sum(r["serum_evidence"] == "TRUE" for r in core_rows),
    }
    print(summary)


if __name__ == "__main__":
    main()
