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

// fail loudly instead of silently cutting through the walls
assert(NX * GRID - TOL > BEAM_LEN + 2 * WALL_DEF, "beam is longer than the tray");

difference() {
    union() {
        gf_tray(NX, NY, H_U, lip = false, magnets = false);
        // one divider -> two channels, each wide enough for a 1x8 beam
        gf_dividers(NX, NY, 1, 2, H_U * HEIGHT_U - HEIGHT_U - 2, wall = 1.2, grip = 0);
    }

    // labels engraved into the cavity floor (debossed into the 7 mm base)
    for (i = [-1, 1])
        translate([BEAM_LEN / 2 - 12, i * (BEAM_W + 26) / 2, HEIGHT_U])
            label_text("1x8", size = 8, depth = 0.6);
}
