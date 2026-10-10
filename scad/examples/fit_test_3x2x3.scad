// Reference tray: 3x2 cells, 3U tall — two channels for 1x8 beams laid flat.
// Serves as a grid/foot fit test and as the first usable tray.
// build:  scad.py build scad/examples/fit_test_3x2x3.scad --name fit_3x2x3 --views iso,top

include <gf.scad>

NX = 3;
NY = 2;
H_U = 3;

BEAM_LEN = 101.6;        // 1x8 beam
BEAM_W   = 12.7;
BEAM_T   = 6.35;

POCKET_L = BEAM_LEN + 3;           // 104.6
POCKET_W = BEAM_W + 5;             // 17.7
POCKET_H = BEAM_T + 1.5;           // 7.85

// fail loudly instead of silently cutting through the walls
assert(NX * GRID - TOL > POCKET_L + 2 * WALL_DEF, "pocket is longer than the tray");
assert(NY * GRID - TOL > 2 * POCKET_W + 3 * WALL_DEF, "two pockets do not fit across");

difference() {
    gf_tray(NX, NY, H_U, lip = false, magnets = false);

    for (i = [-1, 1])
        translate([0, i * (POCKET_W + WALL_DEF) / 2, HEIGHT_U])
            pocket_channel(POCKET_L, POCKET_W, POCKET_H, finger = 7);

    // labels engraved into the cavity floor (debossed into the 7 mm base)
    for (i = [-1, 1])
        translate([POCKET_L / 2 - 12, i * (POCKET_W + WALL_DEF) / 2, HEIGHT_U])
            label_text("1x8", size = 8, depth = 0.6);
}
