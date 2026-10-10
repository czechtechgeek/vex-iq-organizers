# VEX IQ Organizers

Parametrický generátor **pořadačů a vložek na VEX IQ díly** — z katalogu rozměrů dílů
vybereš, co chceš skládat, a vygeneruje se OpenSCAD → STL k tisku. Vložky umí být
**kompatibilní s Gridfinity**, nebo dělané **na míru do originálního kufru od sady**.

Vzniklo pro školní sbírku 14 sad VEX IQ a několik herních sad, kde se díly věčně
míchají. Pokud učíš robotiku a máš ten samý problém, tohle je pro tebe.

> **Stav projektu:** 🚧 rozpracováno — hotová kostra, katalog dílů a ověřený Gridfinity základ.
> Detaily a fáze: [`docs/plan.md`](docs/plan.md) (plán je anglicky, kód a dokumentace taky)

---

## Co to umí (a co ještě ne)

| Fáze | Obsah | Stav |
|---|---|---|
| 0 | Kostra repa, CI, katalog, dokumentace | ✅ hotovo |
| 1 | Katalog dílů (Super Kit, 51 typů, 619 kusů) | 🟡 rozměry z pitchů, 19 dílů čeká na měření |
| 2 | Gridfinity základ dle spec (nožičky, stěny, lip) | ✅ ověřeno (rozměry + vodotěsnost) |
| 3 | Kapsy, popisky, knihovna hotových vložek | 🟡 základ hotový, knihovna se plní |
| 4 | Packer: „vyberu díly → STL" z YAML layoutu | ⬜ plánováno |
| 5 | Vložky na míru do kufru + tisková kampaň pro 14 sad | ⬜ plánováno |
| 6 | Import rozměrů z oficiálních STEP CAD od VEX | ⬜ plánováno |

**Hotové modely:** [MODELS.md](MODELS.md) — generovaný katalog (stav, rozměry, hmotnost, kolik vytištěno).

## Rychlý start

```bash
git clone https://github.com/czechtechgeek/vex-iq-organizers
cd vex-iq-organizers
pip install -r requirements.txt

python3 tools/catalog.py validate          # kontrola katalogu
python3 tools/catalog.py report            # co je hotové, co čeká na měření

# vygenerovat vložku (OpenSCAD musí být v PATH)
export OPENSCADPATH=$PWD/scad/lib
openscad --export-format=binstl -o fit_3x2x3.stl scad/examples/fit_test_3x2x3.scad
```

## Struktura

```
catalog/    parts.yaml (rozměry dílů), kits.yaml (co je v sadě), cases.yaml (kufry)
scad/lib/   gf.scad — Gridfinity základ + kapsy + popisky
scad/       examples/ a trays/ — konkrétní vložky
layouts/    YAML: které díly a kolik chceš poskládat (vstup pro packer)
tools/      catalog.py (validace), measure.py (měření), packer, build
tests/      pytest — invarianty geometrie a katalogu
docs/       plán, jak měřit díly, jak přispět
```

## Gridfinity — čísla, která držíme

| parametr | hodnota |
|---|---|
| mřížka | **42 × 42 mm**, výška **7 mm / U** |
| vnější rozměr boxu | `42n − 0.5 mm` |
| nožička | 0.8 → 1.8 → 2.15 mm (45°/svisle/45°) = **4.75 mm**, 35.6 → 41.5 mm |
| stacking lip | 0.7 / 1.8 / 1.9 mm = **+4.4 mm** |
| magnety | ⌀6 × 2 mm do děr ⌀6.5 × 2.4 mm, středy 13 mm od středu buňky |
| šrouby | M3, ⌀3.2 mm |

Ověřeno testem `tests/test_catalog.py::test_gf_spec_numbers` a vygenerovanou vložkou
3×2×3U: **125.5 × 83.5 × 21.0 mm**, vodotěsná.

## Přispění nového dílu

1. Změř díl šuplerou (viz [`docs/measuring-parts.md`](docs/measuring-parts.md)).
2. Přidej záznam do `catalog/parts.yaml` (`status: measured`).
3. Pokud díl patří do sady, doplň počet do `catalog/kits.yaml`.
4. `python3 tools/catalog.py validate` + `pytest`.

Měření se zapisuje i nástrojem:
`python3 tools/measure.py set beam-1x8 101.7 12.8 6.4`

## Licence

- **Kód** (Python, SCAD skripty): MIT — [`LICENSE`](LICENSE)
- **Modely** (STL, SCAD výstupy, dokumentace): CC BY-SA 4.0 — [`LICENSE-models`](LICENSE-models)

Gridfinity je otevřený standard Zacka Freedmana — díky za něj.
VEX IQ je ochranná známka VEX Robotics; tento projekt s VEXem není nijak spojen.
