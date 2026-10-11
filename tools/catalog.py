#!/usr/bin/env python3
"""
catalog.py — load, derive and validate the VEX IQ parts catalog.

Usage:
    python3 tools/catalog.py validate        # check the catalog (exit 1 on error)
    python3 tools/catalog.py report          # summary: part counts, what still needs measuring
    python3 tools/catalog.py show beam-1x8   # detail of a single part
"""

from __future__ import annotations

import argparse
import pathlib

import yaml

BASE = pathlib.Path(__file__).resolve().parent.parent
CATALOG = BASE / "catalog"

PITCH = 12.7          # mm, VEX IQ
THICK = 6.35          # mm, beam/plate thickness (0.25")
STATUSES = {"derived", "needs_measure", "measured", "spec"}
CATEGORIES = {"beam", "angle_beam", "plate", "pin", "standoff", "shaft",
              "gear", "wheel", "small_part", "accessory", "sensor", "electronics"}


def load(name: str):
    p = CATALOG / name
    if not p.exists():
        raise SystemExit(f"missing {p}")
    return yaml.safe_load(p.read_text(encoding="utf-8"))


def parts() -> list[dict]:
    return load("parts.yaml") or []


def kits() -> list[dict]:
    return load("kits.yaml") or []


def cases() -> list[dict]:
    return load("cases.yaml") or []


def derive(part: dict) -> None:
    """Fill in dimensions derived from the hole count when they are missing."""
    size = part.get("size") or {}
    holes = part.get("holes")
    if holes and not size.get("l"):
        size["l"] = round(holes * PITCH, 2)
        size["h"] = size.get("h") or THICK
        part["size"] = size


def validate() -> list[str]:
    errs: list[str] = []
    ids = set()
    for p in parts():
        pid = p.get("id")
        if not pid:
            errs.append(f"part without id: {p}")
            continue
        if pid in ids:
            errs.append(f"duplicate id: {pid}")
        ids.add(pid)
        if p.get("category") not in CATEGORIES:
            errs.append(f"{pid}: unknown category {p.get('category')!r}")
        if p.get("status") not in STATUSES:
            errs.append(f"{pid}: unknown status {p.get('status')!r}")
        size = p.get("size") or {}
        for axis in ("l", "w", "h"):
            v = size.get(axis)
            if v is not None and (not isinstance(v, (int, float)) or v <= 0):
                errs.append(f"{pid}: size.{axis}={v!r} is not a positive number")
        if p.get("status") == "derived" and (size.get("l") is None or size.get("h") is None):
            errs.append(f"{pid}: status 'derived' but dimensions are missing")
    for k in kits():
        for pid, qty in (k.get("parts") or {}).items():
            if pid.startswith("_"):
                continue
            if pid not in ids:
                errs.append(f"kit {k.get('id')}: unknown part {pid!r}")
            if not isinstance(qty, int) or qty <= 0:
                errs.append(f"kit {k.get('id')}: part {pid!r} has a bad quantity {qty!r}")
    for c in cases():
        if c.get("status") not in STATUSES:
            errs.append(f"case {c.get('id')}: unknown status {c.get('status')!r}")
    return errs


def report() -> None:
    ps = parts()
    pending = [p["id"] for p in ps if p.get("status") == "needs_measure"]
    print(f"parts in catalog: {len(ps)}")
    print(f"  derived from pitch: {sum(1 for p in ps if p.get('status') == 'derived')}")
    print(f"  waiting for calipers: {len(pending)}")
    if pending:
        print("   " + ", ".join(pending))
    print()
    for k in kits():
        n = sum(v for key, v in (k.get("parts") or {}).items() if not key.startswith("_"))
        print(f"kit {k['id']}: {len(k.get('parts') or {})} part types, {n} pieces")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", choices=["validate", "report", "show"])
    ap.add_argument("arg", nargs="?")
    a = ap.parse_args()

    if a.cmd == "validate":
        errs = validate()
        if errs:
            print("catalog errors:")
            for e in errs:
                print("  x", e)
            return 1
        print(f"OK: catalog valid ({len(parts())} parts, {len(kits())} kits, {len(cases())} cases)")
        return 0
    if a.cmd == "report":
        report()
        return 0
    if a.cmd == "show":
        for p in parts():
            if p["id"] == a.arg:
                print(yaml.safe_dump(p, allow_unicode=True, sort_keys=False))
                return 0
        print(f"part {a.arg!r} not found")
        return 1
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
