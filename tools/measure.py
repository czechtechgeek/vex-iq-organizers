#!/usr/bin/env python3
"""
measure.py — print a measuring sheet for parts that still lack measured sizes,
and write measured values back into the catalog.

Usage:
    python3 tools/measure.py sheet                      # markdown sheet, ready to print
    python3 tools/measure.py set <id> <l> <w> <h>       # store a measured size (mm)
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
    out = ["# Measuring sheet — VEX IQ parts", "",
           "Measure with calipers to 0.1 mm. **l** = longer side, **w** = shorter side,",
           "**h** = thickness/height. Beam lengths to 0.5 mm (pitch = 12.7 mm);",
           "for gears measure the outer diameter.", "",
           "| part | name | what to measure | l | w | h | note |",
           "|---|---|---|---|---|---|---|"]
    for p in catalog.parts():
        if p.get("status") == "measured":
            continue
        size = p.get("size") or {}
        need = ", ".join(a for a in ("l", "w", "h") if not size.get(a)) or "verify derived values"
        out.append(f"| `{p['id']}` | {p['name']} | {need} | "
                   f"{size.get('l', '')} | {size.get('w', '')} | {size.get('h', '')} | "
                   f"{p.get('note', '')} |")
    out += ["", "## After measuring", "",
            "```bash",
            "python3 tools/measure.py set beam-1x8 101.7 12.8 6.4",
            "python3 tools/catalog.py validate",
            "pytest -q",
            "```"]
    return "\n".join(out)


def set_size(pid: str, l: float, w: float, h: float) -> int:
    """Write the measured size and status: measured for one part."""
    path = BASE / "catalog" / "parts.yaml"
    text = path.read_text(encoding="utf-8")
    # split into part blocks and rewrite the matching one
    blocks = re.split(r"\n(?=- id: )", text)
    hit = False
    for i, b in enumerate(blocks):
        if re.search(rf"^- id: {re.escape(pid)}\s*$", b, re.M):
            hit = True
            new_size = f"  size: {{l: {l}, w: {w}, h: {h}}}\n"
            if re.search(r"^  size:.*$", b, re.M):
                b = re.sub(r"^  size:.*$", new_size.rstrip("\n"), b, flags=re.M)
            else:
                b = b.rstrip("\n") + "\n" + new_size
            if re.search(r"^  status:.*$", b, re.M):
                b = re.sub(r"^  status:.*$", "  status: measured", b, flags=re.M)
            else:
                b = b.rstrip("\n") + "\n  status: measured\n"
            blocks[i] = b
            break
    if not hit:
        print(f"part {pid!r} not found")
        return 1
    # NOTE: re.split eats the "\n" separator, so join it back
    path.write_text("\n".join(blocks), encoding="utf-8")
    print(f"OK: {pid}: l={l} w={w} h={h} -> status: measured")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", choices=["sheet", "set"])
    ap.add_argument("args", nargs="*")
    a = ap.parse_args()
    if a.cmd == "sheet":
        print(sheet())
        return 0
    if len(a.args) != 4:
        print("usage: measure.py set <id> <l> <w> <h>")
        return 2
    return set_size(a.args[0], float(a.args[1]), float(a.args[2]), float(a.args[3]))


if __name__ == "__main__":
    raise SystemExit(main())
