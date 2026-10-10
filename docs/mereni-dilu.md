# Jak měřit VEX IQ díly

Cíl: dostat do `catalog/parts.yaml` rozměry, které sedí na 0,1 mm, aby kapsy
v pořadači nebyly ani volné, ani těsné.

## Co měřit

| kategorie | měříme | poznámka |
|---|---|---|
| nosníky a desky | délka, šířka, tloušťka | délka má být `počet_děr × 12.7` — ověř na 0,5 mm |
| piny, standoffy, osičky | délka, průměr (u osičky průřez) | u pinu změř i průměr hlavy a těla |
| ozubená kola | vnější průměr, tloušťka, průměr díry | 12T / 36T / 60T / korunové 36T |
| kola | vnější průměr, šířka pneu, šířka náboje | 100 mm a 200 mm travel |
| drobné (washe, spacy, bushingy) | průměr, výška | |

## Jak měřit (aby to bylo použitelné)

1. **Šuplera na 0,1 mm**, díl polož na rovnou podložku.
2. Měř **vnější rozměr přes krajní body**, ne přes díry — díry mají vůli.
3. U kónických dílů (piny s hlavou) měř víc bodů a zapiš ten největší.
4. Když díl existuje ve víc generacích sad, změř **obě** a v katalogu udělej dva záznamy
   (`pin-1x1` a `pin-1x1-2g`).
5. Každé měření zapiš:
   ```bash
   python3 tools/measure.py zapis beam-1x8 101.7 12.8 6.4
   ```
   Nástroj nastaví `stav: zmereno` a rozměry do YAML.

## Kritické rozměry (když není čas měřit všechno)

Prioritu mají díly, které se v pořadači **nejvíc válí**:

1. nosníky 1x4 až 2x20 (odvozené z pitchů — jen ověřit délku),
2. piny 1x1 (nejvíc kusů — 240 v sadě),
3. osičky všech délek,
4. ozubená kola (když mají vlastní kapsy),
5. kola (200 mm travel).

Zbytek (washe, spacy, collar) se dá řešit jednou univerzální mřížkou kapes —
u nich stačí změřit jen průměr.

## Co je v katalogu `stav`

| stav | znamená |
|---|---|
| `odvozeno` | spočteno z pitchů (12.7 mm) — nutno ověřit, ale pravděpodobně sedí |
| `k_mereni` | odhad nebo chybí — bez měření se do vložky nedá spolehnout |
| `zmereno` | ověřeno šuplerou |
| `spec` | dané standardem (Gridfinity mřížka apod.) |
