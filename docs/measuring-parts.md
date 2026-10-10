# How to measure VEX IQ parts

Goal: get dimensions into `catalog/parts.yaml` that are accurate to 0.1 mm, so the
pockets in a tray are neither loose nor tight.

## What to measure

| category | measure | notes |
|---|---|---|
| beams and plates | length, width, thickness | length should be `holes x 12.7` — verify to 0.5 mm |
| pins, standoffs, shafts | length, diameter (shaft: cross section) | for pins also measure head and body diameter |
| gears | outer diameter, thickness, bore | 12T / 36T / 60T / crown 36T |
| wheels | outer diameter, tire width, hub width | 100 mm and 200 mm travel |
| small parts (washers, spacers, bushings) | diameter, height | |

## How to measure (so the numbers are usable)

1. Calipers to **0.1 mm**, part resting on a flat surface.
2. Measure **across the outermost points**, not through the holes — holes have play.
3. For conical parts (pins with a head) measure several points and record the largest.
4. If a part exists in several kit generations, measure **both** and add a second
   catalog entry (`pin-1x1` and `pin-1x1-2g`).
5. Record every measurement:
   ```bash
   python3 tools/measure.py set beam-1x8 101.7 12.8 6.4
   ```
   The tool writes the size and sets `status: measured`.

## Critical dimensions (when you cannot measure everything)

Prioritise the parts that end up strewn across the table:

1. beams 1x4 to 2x20 (derived from pitch — just confirm the length),
2. 1x1 connector pins (240 per kit),
3. shafts of every length,
4. gears (if they get their own pockets),
5. wheels (200 mm travel).

Everything else (washers, spacers, collars) can share one generic grid of pockets —
for those, measuring the diameter is enough.

## Catalog `status` values

| status | meaning |
|---|---|
| `derived` | computed from pitch (12.7 mm) — needs verification, but probably right |
| `needs_measure` | estimate or missing — do not trust it for a fitted pocket |
| `measured` | verified with calipers |
| `spec` | fixed by a standard (e.g. the Gridfinity grid) |
