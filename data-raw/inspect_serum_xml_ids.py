from __future__ import annotations

import sys
import zipfile
from xml.etree import ElementTree as ET


def text_or_empty(parent: ET.Element, tag: str) -> str:
    child = parent.find(f"{{*}}{tag}")
    if child is None or child.text is None:
        return ""
    return child.text.strip()


targets = {x.lower() for x in sys.argv[1:]}

with zipfile.ZipFile("data-raw/serum_metabolites.zip") as zf:
    with zf.open("serum_metabolites.xml") as fh:
        for _, elem in ET.iterparse(fh, events=("end",)):
            if not elem.tag.endswith("metabolite"):
                continue
            name = text_or_empty(elem, "name")
            accession = text_or_empty(elem, "accession")
            pubchem = text_or_empty(elem, "pubchem_compound_id")
            chebi = text_or_empty(elem, "chebi_id")
            kegg = text_or_empty(elem, "kegg_id")
            if not targets or name.lower() in targets or accession.lower() in targets:
                print(accession, name, "PubChem", pubchem, "ChEBI", chebi, "KEGG", kegg)
                if not targets:
                    break
            elem.clear()
