"""Testy katalogu a Gridfinity geometrie."""
from __future__ import annotations

import pathlib
import re
import subprocess
import sys

import pytest

BASE = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BASE / "tools"))

import catalog  # noqa: E402

OPENSCAD = "/usr/bin/openscad"
GF_SCAD = BASE / "scad" / "lib" / "gf.scad"


def test_katalog_je_validni():
    errs = catalog.validate()
    assert errs == [], "chyby v katalogu: " + "; ".join(errs)


def test_odvozene_delky_sedi_s_pitchi():
    for p in catalog.parts():
        if p.get("stav") != "odvozeno":
            continue
        n = p.get("pocet_der")
        r = p.get("rozmer") or {}
        if n and r.get("l"):
            assert abs(r["l"] - n * catalog.PITCH) < 0.01, f"{p['id']}: délka neodpovídá pitchům"


def test_kity_odkazuji_existujici_dily():
    ids = {p["id"] for p in catalog.parts()}
    for k in catalog.kits():
        for pid in (k.get("dily") or {}):
            if not pid.startswith("_"):
                assert pid in ids, f"{k['id']} odkazuje na neznámý díl {pid}"


def gf_constants() -> dict[str, float]:
    """Vytáhne konstanty z gf.scad, aby testy hlídaly shodu se spec."""
    text = GF_SCAD.read_text(encoding="utf-8")
    out = {}
    for m in re.finditer(r"^([A-Z_]+)\s*=\s*([0-9.]+)\s*;", text, re.M):
        out[m.group(1)] = float(m.group(2))
    return out


def test_gf_spec_cisla():
    c = gf_constants()
    # foot: 0.8 + 1.8 + 2.15 = 4.75 mm
    assert abs(c["FOOT_LOW"] + c["FOOT_VERT"] + c["FOOT_UP"] - 4.75) < 1e-9
    # lip: 0.7 + 1.8 + 1.9 = 4.4 mm
    assert abs(c["LIP_LOW"] + c["LIP_VERT"] + c["LIP_UP"] - 4.4) < 1e-9
    # mřížka a výška
    assert c["GRID"] == 42.0 and c["HEIGHT_U"] == 7.0
    assert c["TOL"] == 0.5
    # nožička: dole 35.6, nahoře 41.5
    assert abs((c["GRID"] - 2 * c["FOOT_INSET_BOTTOM"]) - 35.6) < 1e-9
    assert abs((c["GRID"] - 2 * c["FOOT_INSET_TOP"]) - 41.5) < 1e-9
    assert abs((c["GRID"] - 2 * c["FOOT_INSET_VERT"]) - 37.2) < 1e-9
    # magnety dle spec
    assert c["MAGNET_D"] == 6.5 and c["MAGNET_H"] == 2.4 and c["MAGNET_OFFSET"] == 13.0


def stl_bbox(path: pathlib.Path) -> tuple[float, float, float]:
    """Bbox z binárního STL (bez závislostí) — formát: 80 B hlavička, uint32 počet,
    pak 50 B na trojúhelník (12 floatů + 2 B atribut)."""
    import struct

    data = path.read_bytes()
    n = struct.unpack("<I", data[80:84])[0]
    mins = [float("inf")] * 3
    maxs = [float("-inf")] * 3
    off = 84
    for _ in range(n):
        vals = struct.unpack("<12f", data[off:off + 48])
        for k in range(3, 12, 3):          # vrcholy trojúhelníku
            for axis in range(3):
                v = vals[k + axis]
                mins[axis] = min(mins[axis], v)
                maxs[axis] = max(maxs[axis], v)
        off += 50
    return (maxs[0] - mins[0], maxs[1] - mins[1], maxs[2] - mins[2])


@pytest.mark.skipif(not pathlib.Path(OPENSCAD).exists(), reason="OpenSCAD není k dispozici")
def test_vygenerovany_bin_ma_rozmery_dle_spec(tmp_path):
    """3×2×3U vložka musí mít přesně 125.5 × 83.5 × 21 mm (42n - 0.5, 7/U)."""
    scad = tmp_path / "t.scad"
    scad.write_text(f'include <{GF_SCAD}>\ngf_tray(3, 2, 3, lip = false);\n', encoding="utf-8")
    stl = tmp_path / "t.stl"
    r = subprocess.run([OPENSCAD, "--export-format=binstl", "-o", str(stl), str(scad)],
                       capture_output=True, text=True)
    assert r.returncode == 0, r.stderr
    assert stl.read_bytes()[:5] != b"solid", "OpenSCAD vypsal ASCII STL, čekáme binární"
    x, y, z = stl_bbox(stl)
    assert abs(x - (3 * 42 - 0.5)) < 0.05, f"X={x}, čekáno 125.5"
    assert abs(y - (2 * 42 - 0.5)) < 0.05, f"Y={y}, čekáno 83.5"
    assert abs(z - 3 * 7) < 0.05, f"Z={z}, čekáno 21"
