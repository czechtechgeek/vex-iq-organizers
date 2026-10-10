# Plan: VEX IQ parts organizer generator (repo + tool)

**Owner:** Jan Tichý · **Date:** 10 Oct 2026
**Scope:** 14 school VEX IQ kits + at least 3 game sets; parts get mixed up constantly
**Goal:** a public GitHub repo with a **configurable generator of trays/inserts**: from a
library of VEX IQ part dimensions pick the parts you want to store → the tool generates
OpenSCAD → a printable STL. Trays can be **Gridfinity-compatible** or **fitted to the
original kit case**.

---

## 1. Design decisions and why

| Decision | Choice | Why |
|---|---|---|
| Geometry engine | **OpenSCAD** (spec-exact Gridfinity foot + custom pocket modules) | headless on a Raspberry Pi, fully parametric, driven from scripts, no GUI |
| Source of part data | **YAML catalog** (`catalog/parts.yaml`) | human readable, diffable in git, easy to extend |
| Authority for dimensions | (1) official **VEX STEP CAD** (2) caliper measurements | STEP is exact; measuring catches tolerances and generation differences |
| Layout | **declarative layout YAML** + automatic packer | "pick parts and counts" must not mean clicking in CAD |
| Compatibility | Gridfinity **exactly per spec** (42/7 mm) | trays fit existing bins and baseplates |
| Case mode | second output family: insert with a **grid fitted to the case interior** | the original bin (228-8231) is not a multiple of 42 mm, so it needs its own grid plus filler |
| Labels | engraved text (deboss), optional two-colour print via filament swap | students find a part by name, not by shape |
| Licence | code **MIT**, models **CC BY-SA 4.0** | the open-hardware / 3D-printing standard, allows remixes |

**Why not hand-modelling:** 14 kits x dozens of part types = hundreds of combinations;
changing a pocket size must be one number in YAML, not a remodel.

**Why not existing Printables models:** there are Gridfinity trays for plenty of things,
but nothing usable for VEX IQ (12.7 mm pitch beams, pins, shafts, gears); the Robosource
foam inserts are sold as a product and cannot be remixed.

---

## 2. Prior art (and what we reuse)

- **Gridfinity** (Zack Freedman, open standard) — the numbers we must hit:
  - pitch **42 × 42 mm**, height **7 mm / U**, bin = `42n − 0.5 mm`
  - foot: 45 deg 0.8 mm → 1.8 mm vertical → 45 deg 2.15 mm = **4.75 mm**, 35.6 → 41.5 mm, r 3.75
  - stacking lip: 0.7 / 1.8 / 1.9 mm = **+4.4 mm**
  - magnets **6 × 2 mm** in **6.5 × 2.4 mm** holes, centres **13 mm** from the cell centre
  - M3 screws (3.2 mm), wall 1.2 mm, floor 0.8 mm, 0.25 mm clearance per side
- **gridfinity-rebuilt-openscad** (Kennetek) — reference implementation, used to cross-check numbers
- **VEX IQ CAD**: VEX publishes **STEP files for every part**
  (`vexrobotics.com/iq/downloads/cad-snapcad`, 96 MB zip) → most of the catalog can be imported
- **VEX IQ pitch**: 12.7 mm (0.5"); beam thickness 6.35 mm (0.25"); 1x beam 12.7 mm wide, 2x ~25.4 mm
- **Robosource** sells foam inserts for the original bin → confirms both the demand and that the bin is the standard target

---

## 3. Repository layout

```
vex-iq-organizers/
├── README.md                 # what it does, gallery, how to print (Czech)
├── LICENSE                   # MIT (code)
├── LICENSE-models            # CC BY-SA 4.0 (models/STL/SCAD)
├── catalog/
│   ├── parts.yaml            # part library: id, category, size, source
│   ├── kits.yaml             # sets: super-kit-1g, super-kit-2g, classroom-12
│   ├── games.yaml            # game elements (VIQRC) — phase 5
│   └── cases.yaml            # cases/bins/boxes: inner dimensions, grid
├── layouts/
│   ├── _library/             # ready-made generic trays (beams, pins, shafts, gears)
│   ├── super-kit-bin-a.yaml  # a specific layout for the kit case
│   └── drawer-6x4.yaml       # a specific layout for a Gridfinity baseplate
├── scad/
│   ├── lib/gf.scad           # foot + lip + baseplate per spec (tested)
│   ├── lib/pockets.scad      # pockets: rect, round, hex, channel, grid, finger notch
│   ├── lib/labels.scad       # labels (deboss, optional two-colour)
│   ├── lib/tray.scad         # tray shell (walls, floor, stack lip, magnets)
│   └── main.scad             # reads generated data and builds the model
├── tools/
│   ├── catalog.py            # catalog validation, units, derived dimensions
│   ├── measure.py            # measuring sheet + recording measurements
│   ├── import_step.py        # STEP → bbox/volume → catalog (best effort)
│   ├── pack.py               # pack modules into the grid (bin packing)
│   ├── build.py              # layout.yaml → data.scad → STL + PNG + PDF sheet + manifest
│   └── report.py             # shortfalls vs the kit, grams and time estimate
├── tests/                    # pytest: geometry invariants, snapshots, CI
├── docs/
│   ├── measuring-parts.md    # how to measure (calipers, what is critical)
│   ├── adding-a-part.md
│   └── printing.md           # materials, orientation, tolerances, magnets
└── .github/workflows/ci.yml  # tests + build all layouts → STL artifacts
```

---

## 4. Data model (the "config file")

### `catalog/parts.yaml`
```yaml
- id: beam-1x8
  name: "1x8 Beam"
  category: beam
  part_number: "228-2500-007"
  holes: 8
  size: {l: 101.6, w: 12.7, h: 6.35}   # mm; derived from pitch or measured
  status: derived                      # derived | needs_measure | measured | spec
  suggested_pocket: channel            # channel | nest | grid
```

### `catalog/kits.yaml`
```yaml
- id: super-kit-1g
  name: "VEX IQ Super Kit (1st gen)"
  parts:
    beam-1x8: 8
    pin-1x1: 240
    gear-12t: 10
```
`report.py` compares what the designed trays hold against what a kit actually contains
(and how many kits you own → how many copies to print).

### `catalog/cases.yaml`
```yaml
- id: vex-bin-228-8231
  name: "VEX IQ storage bin (228-8231)"
  inner: {l: null, w: null, h: null}   # TO BE MEASURED
  grid: {unit: null, margin: 3.0}
```

### `layouts/super-kit-bin-a.yaml`
```yaml
name: "Super Kit - case A (2x beams + plates)"
target: vex-bin-228-8231
height_u: 5
modules:
  - part: beam-2x8
    count: 6
    pocket: channel
  - part: pin-1x1
    count: 240
    pocket: grid
    dividers: [8, 10]
```

---

## 5. Geometry — SCAD library

- `gf.scad`: `gf_foot()`, `gf_lip()`, `gf_baseplate()` — spec numbers, `$fn` controlled
- `pockets.scad`:
  - `pocket_rect(l, w, h, r, entry, finger)` — chamfered entry, optional finger notch
  - `pocket_round(d, h)`, `pocket_hex(af, h)`
  - `pocket_channel(l, w, h, finger)` — beams, flat or on edge
  - `pocket_grid(nx, ny, d, h, pitch)` — pins, shafts, standoffs
  - `pocket_gear(d, h, bore)` — annular pocket with a shaft cut-out
- `labels.scad`: `label_text("1x8 BEAM", size, depth, orientation)` — `mirror()` where needed
- `tray.scad`: shell with configurable wall, floor, lip and magnet pockets

**Default clearances (tunable per layout):** pocket = part + `0.4 mm`, pin grid = `+0.25 mm`,
pocket depth = part + `1.5 mm` (finger space).

---

## 6. Packer

1. Every module becomes a **rectangle in grid units** (`ceil((length + 2*wall) / 42)`).
2. Placement: first-fit row algorithm, preferring **longest parts at the back**.
3. Validation: modules do not overlap, total width ≤ grid width, pocket height ≤ shell height.
4. Optimisation (phase 5): try rotations and variants, minimise waste/print count.
5. Output: `layout.resolved.json` — exact positions and sizes of every pocket → SCAD input.

---

## 7. Output of one build

```
build/<layout>/
├── tray.stl            # ready to print (multiple parts if larger than the bed)
├── preview_iso.png     # eyeball check (vision_analyze)
├── preview_top.png
├── sheet.pdf           # print sheet: what goes where, how many pieces, labels
├── manifest.json       # dimensions, grams, time estimate, part count
└── README.md           # what to print, orientation, how many copies for 14 kits
```

`manifest.json` + `report.py` also produce a **print campaign**: "for 14 kits you need
tray A x 14, B x 14, C x 14 … = X hours, Y kg of filament".

---

## 8. Tests and CI

- **Invariants (pytest):** pocket ≥ part + clearance; every pocket inside the footprint;
  height a multiple of 7 mm; wall ≥ 1.2 mm; foot and lip match the spec constants;
  modules do not overlap; the tray fits the target case.
- **Snapshots:** hash of the generated `.scad` for reference layouts → geometry changes show up in a PR.
- **Physical check:** `scad.py info` (admesh) → watertight + bbox; previews via `vision_analyze`.
- **CI (GitHub Actions):** tests on push, build every layout in `_library/`, STL as artifacts.

---

## 9. Implementation phases

| Phase | What | Output | Estimate |
|---|---|---|---|
| **0** | Repo, licences, README, CI skeleton | repo on GitHub | 1 session |
| **1** | Catalog: Super Kit (1st and 2nd gen) from public lists + measuring sheet | `parts.yaml`, `kits.yaml` | 1-2 sessions |
| **2** | `gf.scad` (foot/lip/baseplate per spec) + `tray.scad` + spec tests | verified Gridfinity tray 2x2x3U | 1 session |
| **3** | Pockets + labels + first hand-made layouts (pins, shafts, gears) | 3-4 ready trays in `_library/` | 2 sessions |
| **4** | Packer + `build.py` + PDF sheet + manifest | "pick parts → STL" works | 2 sessions |
| **5** | Measure the case and game elements, case layout, print campaign for 14 kits | a full set of case inserts | 2 sessions |
| **6** | `import_step.py` (catalog from VEX STEP), extend to further generations | catalog without manual transcription | 1-2 sessions |

---

## 10. Decisions taken

1. **Visibility:** public (other schools and clubs can reuse it).
2. **First round:** both — the kit case first, then Gridfinity drawer trays.
3. **Calipers:** available (digital) → the catalog will be filled by measurement.
4. **Magnets:** off for now, plain trays (faster prints); can be enabled per layout.

---

## 11. Risks / open questions

- Exact thicknesses and radii of VEX parts cannot be derived from pitch alone → measurement or STEP import.
- Kit generations differ (1st vs 2nd gen) → the catalog needs variants.
- The kit case is not a 42 mm grid → a custom-grid mode; otherwise space is wasted.
- **STEP on the Pi:** `pythonocc`/`cadquery` on aarch64 is uncertain → run the import in
  Docker/on a PC, or fall back to reading dimensions from VEX product pages.
- **Game elements** are large and irregular → a separate chapter, likely a "heap tray"
  rather than fitted pockets.
