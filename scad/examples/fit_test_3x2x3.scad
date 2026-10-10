// Referenční vložka: 3×2 buňky, 3U — dvě kapsy na nosníky 1x8 položené naplocho.
// Slouží k ověření mřížky (42 mm) a nožiček; zároveň první použitelná vložka.
// build:  scad.py build scad/examples/fit_test_3x2x3.scad --name fit_3x2x3 --views iso,top

include <gf.scad>

NX = 3;
NY = 2;
H_U = 3;

NOSNIK = 101.6;          // 1x8 beam
SIRKA  = 12.7;
TL     = 6.35;

KAPSA_L = NOSNIK + 3;              // 104.6
KAPSA_W = SIRKA + 5;               // 17.7
KAPSA_H = TL + 1.5;                // 7.85 (dno kapsy + but to sedí pod okrajem)

// kontrola, že kapsa sedí do půdorysu (ať se chyba neopakuje)
assert(NX * GRID - TOL > KAPSA_L + 2 * WALL_DEF, "kapsa je delší než vložka");
assert(NY * GRID - TOL > 2 * KAPSA_W + 3 * WALL_DEF, "dvě kapsy se nevejdou na šířku");

difference() {
    gf_tray(NX, NY, H_U, lip = false, magnets = false);

    for (i = [-1, 1])
        translate([0, i * (KAPSA_W + WALL_DEF) / 2, HEIGHT_U])
            pocket_channel(KAPSA_L, KAPSA_W, KAPSA_H, finger = 7);

    // popisky vyryté do dna kapsy (deboss do 7mm dna)
    for (i = [-1, 1])
        translate([KAPSA_L / 2 - 12, i * (KAPSA_W + WALL_DEF) / 2, HEIGHT_U])
            label_text("1x8", size = 8, depth = 0.6);
}
