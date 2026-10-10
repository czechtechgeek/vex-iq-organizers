#!/usr/bin/env python3
"""
measure.py — generuje měřicí list pro díly, které ještě nemají změřené rozměry.

Použití:
    python3 tools/measure.py sheet        # markdown list k tisku
    python3 tools/measure.py zapis id l w h   # zapíše změřený rozměr (mm) do parts.yaml
"""

from __future__ import annotations

import argparse
import pathlib
import re
import sys

BASE = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BASE / "tools"))

import catalog  # noqa: E402


def sheet() -> str:
    out = ["# Měřicí list — VEX IQ díly", "",
           "Měřit šuplerou na 0,1 mm. **l** = delší strana, **w** = kratší, **h** = tloušťka/výška.",
           "Délku nosníků měř na 0,5 mm (pitch = 12.7 mm), u ozubených kol měř vnější průměr.", "",
           "| díl | název | co měřit | l | w | h | poznámka |",
           "|---|---|---|---|---|---|---|"]
    for p in catalog.parts():
        if p.get("stav") == "zmereno":
            continue
        r = p.get("rozmer") or {}
        need = ", ".join(a for a in ("l", "w", "h") if not r.get(a)) or "ověřit odvozené hodnoty"
        out.append(f"| `{p['id']}` | {p['nazev']} | {need} | "
                   f"{r.get('l', '')} | {r.get('w', '')} | {r.get('h', '')} | "
                   f"{p.get('poznamka', '')} |")
    out += ["", "## Postup po změření", "",
            "```bash",
            "python3 tools/measure.py zapis beam-1x8 101.7 12.8 6.4",
            "python3 tools/catalog.py validate",
            "pytest -q",
            "```"]
    return "\n".join(out)


def zapis(pid: str, l: float, w: float, h: float) -> int:
    path = BASE / "catalog" / "parts.yaml"
    text = path.read_text(encoding="utf-8")
    # najdi blok dílu a v něm nahraď/přidej rozměr a stav
    blocks = re.split(r"\n(?=- id: )", text)
    hit = False
    for i, b in enumerate(blocks):
        if re.search(rf"^- id: {re.escape(pid)}\s*$", b, re.M):
            hit = True
            new_rozmer = f"  rozmer: {{l: {l}, w: {w}, h: {h}}}\n"
            if re.search(r"^  rozmer:.*$", b, re.M):
                b = re.sub(r"^  rozmer:.*$", new_rozmer.rstrip("\n"), b, flags=re.M)
            else:
                b = b.rstrip("\n") + "\n" + new_rozmer
            if re.search(r"^  stav:.*$", b, re.M):
                b = re.sub(r"^  stav:.*$", "  stav: zmereno", b, flags=re.M)
            else:
                b = b.rstrip("\n") + "\n  stav: zmereno\n"
            blocks[i] = b
            break
    if not hit:
        print(f"díl {pid!r} nenalezen")
        return 1
    # POZOR: split požírá oddělovač "\n" → spojujeme znovu s "\n"
    path.write_text("\n".join(blocks), encoding="utf-8")
    print(f"✓ {pid}: l={l} w={w} h={h} → stav: zmereno")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", choices=["sheet", "zapis"])
    ap.add_argument("args", nargs="*")
    a = ap.parse_args()
    if a.cmd == "sheet":
        print(sheet())
        return 0
    if len(a.args) != 4:
        print("použití: measure.py zapis <id> <l> <w> <h>")
        return 2
    return zapis(a.args[0], float(a.args[1]), float(a.args[2]), float(a.args[3]))


if __name__ == "__main__":
    raise SystemExit(main())
