// Parametric sensor tray — a grid of compartments inside a Gridfinity footprint.
//
// Use it for anything you own many of and want in one place: VEX IQ sensors,
// small parts, game pieces. Compartments are formed by internal dividers, so the
// same file makes "1 cell" compartments and "2 cell" compartments.
//
// Examples:
//   # 16 small compartments (one per cell), 4x4 cells, 5U tall
//   scad.py build scad/examples/sensor_tray.scad --name sensor_small \
//       --set NX=4 --set NY=4 --set H_U=5 --set PX=4 --set PY=4 --views iso,top
//   # 6 large compartments (2 cells each), 4x3 cells
//   scad.py build scad/examples/sensor_tray.scad --name sensor_large \
//       --set NX=4 --set NY=3 --set H_U=5 --set PX=2 --set PY=3 --views iso,top

include <gf.scad>

// ── parameters ───────────────────────────────────────────────────────────────
NX = 4;              // footprint in cells (x)
NY = 4;              // footprint in cells (y)
H_U = 5;             // height in units (5U = 35 mm, cavity 28 mm)
PX = 4;              // compartments across
PY = 4;              // compartments down
DIV_WALL = 1.2;      // divider wall thickness
GRIP = 0;            // grip notch width in the dividers (0 = none)
LABEL = "SENSOR";    // engraved on the cavity floor
LABEL_SIZE = 6;
LIP = false;         // stacking lip (off = fits into a case or drawer)

// ── derived ──────────────────────────────────────────────────────────────────
INNER_X = NX * GRID - TOL - 2 * WALL_DEF;
INNER_Y = NY * GRID - TOL - 2 * WALL_DEF;
DIV_H = H_U * HEIGHT_U - HEIGHT_U - 2;   // dividers 2 mm below the rim
COMP_X = INNER_X / PX;                   // compartment size
COMP_Y = INNER_Y / PY;

assert(DIV_H > 0, "dividers have no height");
assert(COMP_X > 12 && COMP_Y > 12, "compartment too small for a sensor");

difference() {
    union() {
        gf_tray(NX, NY, H_U, lip = LIP, magnets = false);
        // walls that create the PX x PY compartments
        gf_dividers(NX, NY, PX, PY, DIV_H, wall = DIV_WALL, grip = GRIP);
    }

    // label engraved into the cavity floor, along the front edge
    translate([0, -INNER_Y / 2 + 4, HEIGHT_U])
        label_text(LABEL, size = LABEL_SIZE, depth = 0.6);
}
