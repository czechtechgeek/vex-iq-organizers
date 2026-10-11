// Upright rack — items stand on edge to save space.
//
// ITEM_L is the dimension that goes INTO the rack (depth), ITEM_T the thickness
// across the slot, ITEM_H the height of the standing item. The rack walls should
// be lower than ITEM_H so the item sticks out and you can grab it.
//
// Examples:
//   # 3 Robot Brains (1st gen) standing on edge, 4x3 cells
//   scad.py build scad/examples/rack.scad --name rack_brain_upright \
//       --set NX=4 --set NY=3 --set H_U=3 --set N_SLOTS=3 \
//       --set ITEM_L=106.7 --set ITEM_T=41.7 --set ITEM_H=76.2 \
//       --set SLOT_H=40 --set LABEL='"MOZEK"' --views iso,top
//   # controllers (2nd gen) — item sizes are placeholders until measured
//   scad.py build scad/examples/rack.scad --name rack_controller_upright \
//       --set NX=4 --set NY=3 --set H_U=3 --set N_SLOTS=2 \
//       --set ITEM_L=120 --set ITEM_T=60 --set ITEM_H=110 \
//       --set SLOT_H=70 --set LABEL='"OVLADAC"' --views iso,top

include <gf.scad>

// ── the item ─────────────────────────────────────────────────────────────────
ITEM_L = 106.7;      // depth: how far it reaches into the rack (mm)
ITEM_T = 41.7;       // thickness across the slot (mm)
ITEM_H = 76.2;       // height of the standing item (mm)

// ── tray ─────────────────────────────────────────────────────────────────────
NX = 4;              // footprint in cells (x)
NY = 3;              // footprint in cells (y)
H_U = 3;             // height in units
N_SLOTS = 3;         // how many items side by side
SLOT_CLEAR = 3.0;    // clearance per side inside a slot
SLOT_H = 40;         // rack wall height (keep below ITEM_H)
LEAN = 0;            // degrees the walls lean back (costs depth, see RACK_Y)
LIP_H = 10;          // front lip height
LABEL = "MOZEK";     // engraved on the cavity floor
LIP = false;         // stacking lip (off = fits into a case or drawer)

// ── derived ──────────────────────────────────────────────────────────────────
INNER_X = NX * GRID - TOL - 2 * WALL_DEF;
INNER_Y = NY * GRID - TOL - 2 * WALL_DEF;
SLOT_W = ITEM_T + SLOT_CLEAR;
SLOT_D = ITEM_L + SLOT_CLEAR;
RACK_X = N_SLOTS * (SLOT_W + 2.0) + 2.0;
// a leaning item needs extra depth: its top corner swings back by ITEM_H*tan(LEAN)
RACK_Y = SLOT_D + 2.0 + 2 * ITEM_H * tan(LEAN);
RACK_Y_OFF = 4.0;    // shift back to leave room for the label at the front

assert(RACK_X <= INNER_X, "rack is wider than the tray (fewer slots or more cells)");
assert(RACK_Y + RACK_Y_OFF <= INNER_Y, "rack is deeper than the tray (add a cell in y)");
assert(SLOT_H < ITEM_H, "rack walls are taller than the item — you could not grab it");
assert(SLOT_H > 8, "rack walls are too low to hold anything");

difference() {
    union() {
        gf_tray(NX, NY, H_U, lip = LIP, magnets = false);
        translate([0, RACK_Y_OFF, 0])
            gf_slot_rack(N_SLOTS, SLOT_W, SLOT_D, SLOT_H,
                         wall = 2.0, lean = LEAN, lip_h = LIP_H, lip_t = 2.0);
    }

    // label on the cavity floor, in front of the rack
    translate([0, -INNER_Y / 2 + 4, HEIGHT_U])
        label_text(LABEL, size = 6, depth = 0.6);
}
