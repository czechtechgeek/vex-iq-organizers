"""Tests for the model manifest and the generated MODELS.md."""
from __future__ import annotations

import pathlib
import sys

BASE = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BASE / "tools"))

import models  # noqa: E402


def test_manifest_is_valid():
    errs = models.validate()
    assert errs == [], "manifest errors: " + "; ".join(errs)


def test_models_md_is_up_to_date():
    """MODELS.md must be the exact output of tools/models.py md (no drift)."""
    generated = models.render_md()
    current = models.OUT_MD.read_text(encoding="utf-8") if models.OUT_MD.exists() else ""
    assert current == generated, "MODELS.md is stale — run: python3 tools/models.py md"


def test_every_model_id_is_unique_and_named():
    ids = [m["id"] for m in models.models()]
    assert len(ids) == len(set(ids))
    for m in models.models():
        assert m.get("name"), f"{m['id']} has no name"
