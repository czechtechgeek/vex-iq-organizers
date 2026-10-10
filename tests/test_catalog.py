"""Tests for the parts catalog and the Gridfinity geometry."""
from __future__ import annotations

import pathlib
import re
import struct
import subprocess
import sys

import pytest

BASE = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BASE / "tools"))

import catalog  # noqa: E402

OPENSCAD = "/usr/bin/openscad"
GF_SCAD = BASE / "scad" / "lib" / "gf.scad"


def test_catalog_is_valid():
    errs = catalog.validate()
    assert errs == [], "catalog errors: " + "; ".join(errs)


def test_derived_lengths_match_pitch():
    for p in catalog.parts():
        if p.get("status") != "derived":
            continue
        holes = p.get("holes")
        size = p.get("size") or {}
        if holes and size.get("l"):
            assert abs(size["l"] - holes * catalog.PITCH) < 0.01, f"{p['id']}: length does not match pitch"


def test_kits_reference_existing_parts():
    ids = {p["id"] for p in catalog.parts()}
    for k in catalog.kits():
        for pid in (k.get("parts") or {}):
            if not pid.startswith("_"):
                assert pid in ids, f"{k['id']} references unknown part {pid}"


def gf_constants() -> dict[str, float]:
    """Pull the constants out of gf.scad so tests guard the spec numbers."""
    text = GF_SCAD.read_text(encoding="utf-8")
    out = {}
    for m in re.finditer(r"^([A-Z_]+)\s*=\s*([0-9.]+)\s*;", text, re.M):
        out[m.group(1)] = float(m.group(2))
    return out


def test_gf_spec_numbers():
    c = gf_constants()
    # foot: 0.8 + 1.8 + 2.15 = 4.75 mm
    assert abs(c["FOOT_LOW"] + c["FOOT_VERT"] + c["FOOT_UP"] - 4.75) < 1e-9
    # lip: 0.7 + 1.8 + 1.9 = 4.4 mm
    assert abs(c["LIP_LOW"] + c["LIP_VERT"] + c["LIP_UP"] - 4.4) < 1e-9
    # grid and height unit
    assert c["GRID"] == 42.0 and c["HEIGHT_U"] == 7.0
    assert c["TOL"] == 0.5
    # foot footprint: 35.6 at the bottom, 41.5 at the top
    assert abs((c["GRID"] - 2 * c["FOOT_INSET_BOTTOM"]) - 35.6) < 1e-9
    assert abs((c["GRID"] - 2 * c["FOOT_INSET_TOP"]) - 41.5) < 1e-9
    assert abs((c["GRID"] - 2 * c["FOOT_INSET_VERT"]) - 37.2) < 1e-9
    # magnets per spec
    assert c["MAGNET_D"] == 6.5 and c["MAGNET_H"] == 2.4 and c["MAGNET_OFFSET"] == 13.0


def stl_bbox(path: pathlib.Path) -> tuple[float, float, float]:
    """Bounding box of a binary STL, no dependencies: 80 B header, uint32 count,
    then 50 B per triangle (12 floats + 2 B attribute)."""
    data = path.read_bytes()
    n = struct.unpack("<I", data[80:84])[0]
    mins = [float("inf")] * 3
    maxs = [float("-inf")] * 3
    off = 84
    for _ in range(n):
        vals = struct.unpack("<12f", data[off:off + 48])
        for k in range(3, 12, 3):          # triangle vertices
            for axis in range(3):
                v = vals[k + axis]
                mins[axis] = min(mins[axis], v)
                maxs[axis] = max(maxs[axis], v)
        off += 50
    return (maxs[0] - mins[0], maxs[1] - mins[1], maxs[2] - mins[2])


@pytest.mark.skipif(not pathlib.Path(OPENSCAD).exists(), reason="OpenSCAD not available")
def test_rendered_tray_matches_spec(tmp_path):
    """A 3x2x3U tray must measure exactly 125.5 x 83.5 x 21 mm (42n - 0.5, 7/U)."""
    scad = tmp_path / "t.scad"
    scad.write_text(f'include <{GF_SCAD}>\ngf_tray(3, 2, 3, lip = false);\n', encoding="utf-8")
    stl = tmp_path / "t.stl"
    r = subprocess.run([OPENSCAD, "--export-format=binstl", "-o", str(stl), str(scad)],
                       capture_output=True, text=True)
    assert r.returncode == 0, r.stderr
    assert stl.read_bytes()[:5] != b"solid", "OpenSCAD produced ASCII STL, expected binary"
    x, y, z = stl_bbox(stl)
    assert abs(x - (3 * 42 - 0.5)) < 0.05, f"X={x}, expected 125.5"
    assert abs(y - (2 * 42 - 0.5)) < 0.05, f"Y={y}, expected 83.5"
    assert abs(z - 3 * 7) < 0.05, f"Z={z}, expected 21"
