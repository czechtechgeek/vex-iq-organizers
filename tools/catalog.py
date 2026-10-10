#!/usr/bin/env python3
"""
catalog.py — načtení, odvození a validace katalogu VEX IQ dílů.

Použití:
    python3 tools/catalog.py validate        # zkontroluje katalog (exit 1 při chybě)
    python3 tools/catalog.py report          # souhrn: počty dílů, co chybí změřit
    python3 tools/catalog.py show beam-1x8   # detail jednoho dílu
"""

from __future__ import annotations

import argparse
import pathlib
import sys

import yaml

BASE = pathlib.Path(__file__).resolve().parent.parent
CATALOG = BASE / "catalog"

PITCH = 12.7          # mm, VEX IQ
THICK = 6.35          # mm, tloušťka nosníku/desky (0.25")
STAVY = {"odvozeno", "k_mereni", "zmereno", "spec"}


def load(name: str):
    p = CATALOG / name
    if not p.exists():
        raise SystemExit(f"chybí {p}")
    return yaml.safe_load(p.read_text(encoding="utf-8"))


def parts() -> list[dict]:
    return load("parts.yaml") or []


def kits() -> list[dict]:
    return load("kits.yaml") or []


def cases() -> list[dict]:
    return load("cases.yaml") or []


def derive(part: dict) -> None:
    """Doplní odvozené rozměry z počtu děr (kde chybí)."""
    r = part.get("rozmer") or {}
    n = part.get("pocet_der")
    if n and not r.get("l"):
        r["l"] = round(n * PITCH, 2)
        r["h"] = r.get("h") or THICK
        part["rozmer"] = r


def validate() -> list[str]:
    errs: list[str] = []
    ids = set()
    for p in parts():
        pid = p.get("id")
        if not pid:
            errs.append(f"díl bez id: {p}")
            continue
        if pid in ids:
            errs.append(f"duplicitní id: {pid}")
        ids.add(pid)
        if p.get("kategorie") not in {"beam", "beam_uhlovy", "plate", "pin",
                                     "standoff", "shaft", "gear", "wheel", "drobne", "doplnek"}:
            errs.append(f"{pid}: neznámá kategorie {p.get('kategorie')!r}")
        if p.get("stav") not in STAVY:
            errs.append(f"{pid}: neznámý stav {p.get('stav')!r}")
        r = p.get("rozmer") or {}
        for axis in ("l", "w", "h"):
            v = r.get(axis)
            if v is not None and (not isinstance(v, (int, float)) or v <= 0):
                errs.append(f"{pid}: rozmer.{axis}={v!r} není kladné číslo")
        if p.get("stav") == "odvozeno" and (r.get("l") is None or r.get("h") is None):
            errs.append(f"{pid}: stav 'odvozeno', ale chybí rozměry")
    known = ids
    for k in kits():
        for pid, qty in (k.get("dily") or {}).items():
            if pid.startswith("_"):
                continue
            if pid not in known:
                errs.append(f"kit {k.get('id')}: neznámý díl {pid!r}")
            if not isinstance(qty, int) or qty <= 0:
                errs.append(f"kit {k.get('id')}: díl {pid!r} má divný počet {qty!r}")
    for c in cases():
        if c.get("stav") not in STAVY:
            errs.append(f"case {c.get('id')}: neznámý stav {c.get('stav')!r}")
    return errs


def report() -> None:
    ps = parts()
    k_mereni = [p["id"] for p in ps if p.get("stav") == "k_mereni"]
    print(f"dílů v katalogu: {len(ps)}")
    print(f"  odvozeno z pitchů: {sum(1 for p in ps if p.get('stav') == 'odvozeno')}")
    print(f"  k měření šuplerou: {len(k_mereni)}")
    if k_mereni:
        print("   " + ", ".join(k_mereni))
    print()
    for k in kits():
        n = sum(v for kk, v in (k.get("dily") or {}).items() if not kk.startswith("_"))
        print(f"kit {k['id']}: {len(k.get('dily') or {})} typů dílů, {n} kusů")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", choices=["validate", "report", "show"])
    ap.add_argument("arg", nargs="?")
    a = ap.parse_args()

    if a.cmd == "validate":
        errs = validate()
        if errs:
            print("CHYBY v katalogu:")
            for e in errs:
                print("  ✗", e)
            return 1
        print(f"✓ katalog v pořádku ({len(parts())} dílů, {len(kits())} sestav, {len(cases())} boxů)")
        return 0
    if a.cmd == "report":
        report()
        return 0
    if a.cmd == "show":
        for p in parts():
            if p["id"] == a.arg:
                print(yaml.safe_dump(p, allow_unicode=True, sort_keys=False))
                return 0
        print(f"díl {a.arg!r} nenalezen")
        return 1
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
