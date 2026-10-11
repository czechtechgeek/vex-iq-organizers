// Parametric holder for a bulky item — battery, controller, robot brain.
//
// The item lies on the tray floor and a fitted frame (thin walls) keeps it in
// place; a grip gap lets you pinch it out. Set ITEM_L/W/H to the measured size
// and the cells to the smallest footprint that fits (the asserts tell you).
//
// Examples:
//   # VEX IQ Robot Brain (1st gen, 228-2540): 4.2 x 3.0 x 1.64 in with battery
//   scad.py build scad/examples/holder.scad --name holder_brain_1g \
//       --set ITEM_L=106.7 --set ITEM_W=76.2 --set ITEM_H=41.7 \
//       --set NX=3 --set NY=3 --set H_U=5 --set FRAME_H=18 --set FINGER=30 \
//       --set LABEL='"MOZEK 1G"' --views iso,top
//   # Robot Battery (2nd gen, 228-7045) — size must be measured first
//   scad.py build scad/examples/holder.scad --name holder_battery \
//       --set ITEM_L=95 --set ITEM_W=60 --set ITEM_H=25 \
//       --set NX=3 --set NY=2 --set H_U=4 --set FRAME_H=12 --set FINGER=25 \
//       --set LABEL='"BATERIE"' --views iso,top

include <gf.scad>

// ── the item ─────────────────────────────────────────────────────────────────
ITEM_L = 106.7;      // length (x), mm
ITEM_W = 76.2;       // width (y), mm
ITEM_H = 41.7;       // height — only used for the checks and the notes

// ── tray ─────────────────────────────────────────────────────────────────────
NX = 3;              // footprint in cells (x)
NY = 3;              // footprint in cells (y)
H_U = 5;             // height in units
FRAME_H = 18;        // how high the frame holds the item (may be < ITEM_H)
CLEAR = 1.5;         // clearance per side
FRAME_W = 2.0;       // frame wall thickness
FINGER = 30;         // grip gap across the middle (0 = none)
LABEL = "MOZEK 1G";  // engraved on the cavity floor
LIP = false;         // stacking lip (off = fits into a case or drawer)

// ── derived ──────────────────────────────────────────────────────────────────
INNER_X = NX * GRID - TOL - 2 * WALL_DEF;
INNER_Y = NY * GRID - TOL - 2 * WALL_DEF;
FRAME_L = ITEM_L + 2 * CLEAR + 2 * FRAME_W;
FRAME_WD = ITEM_W + 2 * CLEAR + 2 * FRAME_W;
CAVITY_H = H_U * HEIGHT_U - HEIGHT_U;

assert(FRAME_L <= INNER_X, "item + frame does not fit across (add a cell in x)");
assert(FRAME_WD <= INNER_Y, "item + frame does not fit down (add a cell in y)");
assert(FRAME_H <= CAVITY_H, "frame is taller than the tray cavity");
assert(ITEM_H > 0, "item height must be positive");

difference() {
    union() {
        gf_tray(NX, NY, H_U, lip = LIP, magnets = false);
        gf_frame(ITEM_L, ITEM_W, FRAME_H, clear = CLEAR, wall = FRAME_W, finger = FINGER);
    }

    // label on the cavity floor, in front of the frame
    translate([0, -INNER_Y / 2 + 4, HEIGHT_U])
        label_text(LABEL, size = 6, depth = 0.6);
}
