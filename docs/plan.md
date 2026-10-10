# Plán: generátor pořadačů na VEX IQ díly (repo + nástroj)

**Zadavatel:** Jan Tichý · **Datum:** 10. 10. 2026
**Rozsah:** 14 sad VEX IQ + ≥3 hry, potřeba lepší organizace ve škole
**Cíl:** veřejné (nebo privátní)GitHub repo s **konfigurovatelným generátorem vložek/pořadačů**:
z knihovny rozměrů VEX IQ dílů sestavím požadovanou sestavu kapes → vygeneruje se
OpenSCAD → STL k tisku. Kompatibilní s **Gridfinity**, plus režim „na míru do originálního
kufru od sady".

---

## 1. Jak to udělat nejlépe — rozhodnutí se zdůvodněním

| Rozhodnutí | Volba | Proč |
|---|---|---|
| Vykreslovací jádro | **OpenSCAD** (`gridfinity-foot` dle spec + vlastní moduly kapes) | funguje na Pi headless, parametricky se dá generovat ze skriptu, žádné GUI |
| Zdroj dat o dílech | **YAML katalog** (`catalog/parts.yaml`) | čitelné, diffovatelné v gitu, snadno se doplňuje |
| Autorita rozměrů | (1) oficiální **STEP CAD od VEX** (2) měření šuplerou | STEP je přesný; měření zachytí odchylky a varianty generací |
| Rozvržení | **deklarativní layout YAML** + automatický packer | „vyberu díly a kolik jich chci" není ruční klikání v CADu |
| Kompatibilita | Gridfinity **přesně dle spec** (42/7 mm) | díly pasují do hotových zásobníků a baseplate, které už existují |
| Režim „do kufru" | druhá rodina výstupů: vložka s **mřížkou na míru** vnitřku kufru | originální bin (228-8231) není 42mm násobek, potřebuje vlastní grid + vyplňky |
| Popisky | vyrytý text (deboss) + volitelný 2barevný tisk přes výměnu filamentu | žák najde díl podle jména, ne podle tvaru |
| Licence | kód **MIT**, modely **CC BY-SA 4.0** | standard pro open-hardware/3D tisk, umožní remixy |

**Proč ne ruční modelování:** 14 sad × desítky typů dílů = stovky kombinací; měnit
rozměr kapsy musí být změna jednoho čísla v YAML, ne přemodelování.

**Proč ne hotové modely z Printables:** existují Gridfinity pořadače na leccos, ale na
VEX IQ (specifické délky nosníků 12.7mm pitch, piny, osičky, ozubená kola) nic použitelného;
pěnové vložky od Robosource se prodávají a nejde je remixovat.

---

## 2. Co už existuje (a co z toho použijeme)

- **Gridfinity** (Zack Freedman, otevřený standard) — čísla, která musíme dodržet:
  - pitch **42 × 42 mm**, výška **7 mm / U**, bin = `42n − 0.5 mm`
  - nožička (foot): 45° 0.8 mm → 1.8 mm svisle → 45° 2.15 mm, celkem **4.75 mm**, dole 35.6 mm, r 3.75
  - stacking lip: 0.7 / 1.8 / 1.9 mm = **+4.4 mm**
  - magnety **⌀6 × 2 mm** do děr **⌀6.5 × 2.4 mm**, středy **13 mm** od středu buňky (26 mm rozteč)
  - šrouby M3 (⌀3.2 mm průchozí), stěna 1.2 mm, dno 0.8 mm, vůle 0.25 mm na stranu
- **gridfinity-rebuilt-openscad** (Kennetek) — referenční implementace, bereme jako kontrolu čísel
- **VEX IQ CAD**: VEX zveřejňuje **STEP pro každý díl** (`vexrobotics.com/iq/downloads/cad-snapcad`, zip 96 MB) → katalog se dá z velké části naimportovat automaticky
- **VEX IQ pitch**: 12.7 mm (0.5"), tloušťka nosníku 6.35 mm (0.25"); 1x beam široký 1 pitch, 2x beam ~2 pitch
- **Robosource** prodává pěnové vložky do originálního binu → potvrzuje, že poptávka existuje a že bin je standardní cíl

---

## 3. Struktura repa

```
vex-iq-organizers/
├── README.md                 # co to umí, fotky, jak tisknout, galerie hotových vložek
├── LICENSE                   # MIT (kód)
├── LICENSE-models            # CC BY-SA 4.0 (modely/STL/SCAD)
├── catalog/
│   ├── parts.yaml            # knihovna dílů: id, kategorie, rozměry, hmotnost, zdroj
│   ├── kits.yaml             # sestavy: super-kit-1g, super-kit-2g, classroom-12, add-ony
│   ├── games.yaml            # herní elementy (VIQRC) — až ve fázi 3
│   └── cases.yaml            # kufry/biny/boxy: vnitřní rozměry, výška, grid
├── layouts/
│   ├── _library/             # hotové obecné vložky (nosníky, piny, osičky, kola, kola-ozubená)
│   ├── super-kit-bin-a.yaml  # konkrétní sestava do kufru
│   └── drawer-6x4.yaml       # do šuplíku na Gridfinity baseplate
├── scad/
│   ├── lib/gf.scad           # foot + lip + baseplate dle spec (testováno)
│   ├── lib/pockets.scad      # kapsy: obdélník, kruh, hex, kanál, mřížka, „nehet"
│   ├── lib/labels.scad       # popisky (deboss, volitelně 2 barvy)
│   ├── lib/tray.scad         # skořápka vložky (stěny, dno, stack lip, magnety)
│   └── main.scad             # načte vygenerovaná data a postaví model
├── tools/
│   ├── catalog.py            # validace katalogu, jednotky, dopočty (délka z pitch)
│   ├── import_step.py        # STEP → bbox/objem → doplnění katalogu (best effort)
│   ├── measure.py            # tisk měřicího listu + zápis naměřených hodnot
│   ├── pack.py               # rozvržení modulů do mřížky (bin packing)
│   ├── build.py              # layout.yaml → data.scad → STL + PNG + PDF list + manifest
│   └── report.py             # kolik kusů chybí/přebývá proti sadě, odhad gramů a času
├── tests/                    # pytest: invarianty geometrie + snapshoty + CI
├── docs/
│   ├── mereni-dilu.md        # jak měřit (šuplera, co měřit, co je kritické)
│   ├── jak-pridat-dil.md
│   └── tisk.md               # materiály, orientace, tolerance, kdy magnety
└── .github/workflows/ci.yml  # testy + build všech layoutů → artefakty STL
```

---

## 4. Datový model (to je ten „konfigurák")

### `catalog/parts.yaml`
```yaml
- id: beam-1x8
  nazev: "1x8 Beam"
  kategorie: beam
  rozmer: {l: 108.0, w: 12.7, h: 8.6}      # mm; zdroj: measured|vex-step|pitch
  pitch_len: 8                              # počet děr (odvozené rozměry)
  hmotnost_g: 8.4
  zdroj: measured                           # measured | vex-step | odvozeno
  poznamka: "sedí i pro 2. gen"
- id: pin-connector-1x1
  nazev: "Connector Pin 1x1"
  kategorie: pin
  rozmer: {l: 12.7, w: 8.0, h: 8.0}
```
Pravidla: rozměry vždy v mm, `l/w/h` = **bounding box v orientaci „jak leží v kapse"**,
u deltových věcí (gear, wheel hub) navíc `prumer:`. Každý záznam má `zdroj:`.

### `catalog/kits.yaml`
```yaml
- id: super-kit
  nazev: "VEX IQ Super Kit (1. gen)"
  dily:
    beam-1x3: 2
    beam-1x4: 6
    beam-1x8: 8
    pin-connector-1x1: 240
    gear-12t: 10
    ...
```
Použití: `report.py` porovná, co se vejde do navržených vložek, proti tomu, co v sadě
skutečně je (a kolik sad vlastníš → kolik vložek vytisknout).

### `catalog/cases.yaml`
```yaml
- id: vex-bin-228-8231
  nazev: "Originální storage bin VEX IQ"
  vnitrni: {l: 0, w: 0, h: 0}       # DOPLNIT MĚŘENÍM
  mrizka: {unita: 40, okraj: 3}     # navrhne packer, aby seděla
  poznamka: "kufr, co byl u sad; vejde se i Chromebook"
```

### `layouts/super-kit-bin-a.yaml`
```yaml
nazev: "Super Kit – kufr A (nosníky 2x + desky)"
cil: vex-bin-228-8231
vyska_u: 5
moduly:
  - dil: beam-2x8
    pocet: 6
    kapsa: kanál          # dlouhá drážka s nehtem na vytažení
  - dil: beam-2x20
    pocet: 2
    kapsa: kanál
  - dil: plate-4x4
    pocet: 4
    kapsa: hnízdo         # obdélníková kapsa + vybrání na prst
  - dil: pin-connector-1x1
    pocet: 240
    kapsa: mřížka
    delice: [8, 10]       # mřížka 8×10 kapes
```

---

## 5. Geometrie — SCAD knihovna

- `gf.scad`: `gf_foot()`, `gf_lip()`, `gf_baseplate()` — čísla dle spec, verze `$fn` řízená
- `pockets.scad`:
  - `pocket_rect(l, w, h, r, nabet, nehet)` — obdélníková kapsa se zkoseným vstupem a vybráním
  - `pocket_round(d, h)`, `pocket_hex(af, h)`
  - `pocket_channel(l, w, h, nehet)` — pro nosníky (volitelně „stojaté" nebo „naplocho")
  - `pocket_grid(nx, ny, d, h, roztec)` — mřížka malých kapes (piny, osičky, kolíky)
  - `pocket_gear(d, h, hridel)` — mezikruží s výřezem pro osu
- `labels.scad`: `label_text("1x8 BEAM", velikost, hloubka, orientace)` — `mirror()` tam, kde je potřeba
- `tray.scad`: skořápka s konfigurovatelnou stěnou, dnem, lipem a magnetovými kapsami

**Vůle (default, laditelné jedním parametrem v layoutu):** kapsa = díl + `0.4 mm`,
mřížka pinu = +`0.25 mm`, výška kapsy = díl + `1.5 mm` (na prsty).

---

## 6. Packer (rozvržení)

1. Každý modul se převede na **obdélník v jednotkách mřížky** (`ceil((délka+2*stěna)/42)`).
2. Skládání: řádkový algoritmus (první vhodný slot) s preferencí **nejdelší díly nahoru dozadu**.
3. Validace: moduly se nepřekrývají, součet šířek ≤ šířka mřížky, výška kapes ≤ výška skořápky.
4. Optimalizace (fáze 5): zkoušet rotace a varianty rozložení, minimalizovat odpad/počet tisků.
5. Výstup: `layout.resolved.json` = přesné pozice a rozměry každé kapsy → vstup pro SCAD.

---

## 7. Výstup jednoho buildu

```
build/<layout>/
├── tray.stl            # k tisku (nebo víc dílů, když je větší než podložka)
├── nahled_iso.png      # kontrola očima (vision_analyze)
├── nahled_top.png
├── list.pdf            # tiskový list: co je kde, kolik kusů, popisky
├── manifest.json       # rozměry, gramáž, odhad času, počet dílů
└── README.md           # co tisknout, jak orientovat, kolik kopií pro 14 sad
```

`manifest.json` + `report.py` dají i **tiskovou kampaň**: „pro 14 sad potřebuješ
tisknout vložku A × 14, B × 14, C × 14 … = X hodin, Y kg filamentu".

---

## 8. Testy a CI (aby to nezdegenerovalo)

- **Invarianty (pytest):** kapsa ≥ díl + vůle; každá kapsa uvnitř půdorysu; výška = násobek 7 mm;
  stěna ≥ 1.2 mm; foot + lip odpovídají spec (čísla porovnaná proti konstantám);
  moduly se nepřekrývají; vložka se vejde do cílového boxu.
- **Snapshoty:** hash vygenerovaného `.scad` pro referenční layouty → změna geometrie je vidět v PR.
- **Fyzická kontrola:** `scad.py info` (admesh) → vodotěsnost + bbox; náhledy přes `vision_analyze`.
- **CI (GitHub Actions):** testy na push, build všech layoutů v `_library/`, STL jako artefakty.

---

## 9. Fáze implementace (odhady práce)

| Fáze | Co | Výstup | Odhad |
|---|---|---|---|
| **0** | Založit repo, licence, README, CI kostra | repo na GitHubu | 1 session |
| **1** | Katalog: Super Kit (1. i 2. gen) z veřejných seznamů + měřicí list na doplnění | `parts.yaml`, `kits.yaml` | 1–2 session |
| **2** | `gf.scad` (foot/lip/baseplate dle spec) + `tray.scad` + testy spec | ověřená Gridfinity vložka 2×2×3U | 1 session |
| **3** | Kapsy + popisky + první ruční layout (piny, osičky, ozubená kola) | 3–4 hotové vložky v `_library/` | 2 sessions |
| **4** | Packer + `build.py` + PDF list + manifest | „vyberu díly → STL" funguje | 2 sessions |
| **5** | Měření kufru a herních elementů, layout do kufru, tisková kampaň pro 14 sad | sada vložek do kufru | 2 sessions |
| **6** | `import_step.py` (katalog z VEX STEP), rozšíření na další generace | katalog bez ručního opisování | 1–2 session |

---

## 10. Rozhodnutí k potvrzení

1. **Viditelnost repa** — veřejné (doporučuji, ať z toho mají i jiné školy) vs. privátní.
2. **Šuplera** — máš doma? Podle toho, jak přesný bude katalog (bez měření pojedeme z pitchů a STEP dat a doplníme později).
3. **Priorita prvního kola** — (a) vložka do originálního kufru, (b) Gridfinity vložky do šuplíku, (c) obojí.
4. **Magnety** — kapsy na magnety (⌀6×2) zapnout hned, nebo až bude potřeba (zvyšuje čas tisku a chce magnetky doma).
5. **Oblast prvního kola** — nosníky + piny + osičky, nebo hned všechno včetně ozubených kol a kol.

---

## 11. Rizika / otevřené otázky

- **Přesné tloušťky a rádiusy** VEX dílů nejdou jen z pitchů → nutné měření nebo STEP import.
- **Generace sad**: 1. a 2. gen se v detailech liší (jiné barvy/piny) → katalog musí mít varianty.
- **Kufr není 42mm mřížka** → režim „na míru" s vlastním gridem; jinak se plýtvá místem.
- **Pi a STEP**: `pythonocc`/`cadquery` na aarch64 je nejisté → import STEP plánuji řešit
  buď v Dockeru/na PC, nebo redukovat na „přečti rozměry z VEX stránky produktu".
- **Herní elementy** (3 hry) mají jiné rozměry, často velké a nepravidelné → samostatná kapitola,
  možná spíš „podnos na hromadu" než kapsa na míru.
