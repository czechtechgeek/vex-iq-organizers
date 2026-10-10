// Fit test Gridfinity: 2×2 buňky, 3U vysoká vložka + jedna kapsa na 1x8 nosník.
// Slouží jako referenční díl pro ověření, že nám sedí mřížka (42 mm) a nožičky.
// build:  scad.py build scad/examples/fit_test_2x2x3.scad --name fit_2x2x3 --views iso,top

include <gf.scad>

NX = 2;
NY = 2;
H_U = 3;

KAPSA_L = 101.6 + 4;   // 1x8 beam (101.6) + vůle na stěny kapsy
KAPSA_W = 12.7 + 6;
KAPSA_H = 6.35 + 1.5;

difference() {
    gf_tray(NX, NY, H_U, lip = false, magnets = false);

    // dvě kapsy na nosníky 1x8 vedle sebe (naplocho)
    translate([0, -14, HEIGHT_U])   // dno kapsy = dno dutiny
        pocket_channel(KAPSA_L, KAPSA_W, KAPSA_H + 4, finger = 6);

    // popisek na dně druhé kapsy (deboss)
    translate([0, 14, HEIGHT_U + KAPSA_H + 4 - 0.6])
        label_text("1x8 BEAM", size = 6, depth = 0.6);
}
