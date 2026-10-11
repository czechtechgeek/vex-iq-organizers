// ─────────────────────────────────────────────────────────────────────────────
// gf.scad — Gridfinity base geometry per the open spec (gridfinity.xyz)
// Numbers come from the spec and from the reference implementation
// (gridfinity-rebuilt-openscad). Do not round them by eye — if a value changes,
// update tests/test_catalog.py as well.
// ─────────────────────────────────────────────────────────────────────────────

// grid and heights
GRID        = 42.0;   // cell pitch
HEIGHT_U    = 7.0;    // one height unit
TOL         = 0.5;    // bin = 42n - 0.5 (0.25 mm per side)

// foot, bottom to top: 45 deg / vertical / 45 deg
FOOT_LOW    = 0.8;
FOOT_VERT   = 1.8;
FOOT_UP     = 2.15;   // total 4.75
FOOT_H      = FOOT_LOW + FOOT_VERT + FOOT_UP;
FOOT_INSET_BOTTOM = 3.2;   // 42 - 35.6
FOOT_INSET_VERT   = 2.4;   // 42 - 37.2
FOOT_INSET_TOP    = 0.25;  // 42 - 41.5
FOOT_R_BOTTOM = 0.8;
FOOT_R_VERT   = 1.6;
FOOT_R_TOP    = 3.75;

// stacking lip, bottom to top: 0.7 / 1.8 / 1.9
LIP_LOW     = 0.7;
LIP_VERT    = 1.8;
LIP_UP      = 1.9;
LIP_H       = LIP_LOW + LIP_VERT + LIP_UP;   // 4.4

// magnets and screws
MAGNET_D      = 6.5;   // for a 6 x 2 mm magnet
MAGNET_H      = 2.4;
MAGNET_OFFSET = 13.0;  // from the cell centre
SCREW_D       = 3.2;   // M3

// walls
WALL_DEF    = 1.2;
FLOOR_DEF   = 0.8;

$fn = 64;

// ── 2D profiles ──────────────────────────────────────────────────────────────
// square of side 42-2*inset with rounded corners of radius r (centred)
module gf_profile(inset, r) {
    offset(r = r) square([GRID - 2 * inset - 2 * r, GRID - 2 * inset - 2 * r], center = true);
}

// outer body footprint (nx x ny cells, minus tolerance)
module body_profile(nx, ny, r = FOOT_R_TOP) {
    offset(r = r) square([nx * GRID - TOL - 2 * r, ny * GRID - TOL - 2 * r], center = true);
}

// thin slice of a profile (helper for hull)
module gf_slice(z, inset, r, t = 0.06) {
    translate([0, 0, z]) linear_extrude(height = t) gf_profile(inset, r);
}

// ── single-cell foot ─────────────────────────────────────────────────────────
module gf_foot_cell() {
    hull() {
        gf_slice(0, FOOT_INSET_BOTTOM, FOOT_R_BOTTOM);
        gf_slice(FOOT_LOW, FOOT_INSET_VERT, FOOT_R_VERT);
    }
    hull() {
        gf_slice(FOOT_LOW, FOOT_INSET_VERT, FOOT_R_VERT);
        gf_slice(FOOT_LOW + FOOT_VERT, FOOT_INSET_VERT, FOOT_R_VERT);
    }
    hull() {
        gf_slice(FOOT_LOW + FOOT_VERT, FOOT_INSET_VERT, FOOT_R_VERT);
        gf_slice(FOOT_H, FOOT_INSET_TOP, FOOT_R_TOP);
    }
}

module gf_feet(nx, ny) {
    for (i = [0 : nx - 1], j = [0 : ny - 1])
        translate([(i - (nx - 1) / 2) * GRID, (j - (ny - 1) / 2) * GRID, 0])
            gf_foot_cell();
}

// ── magnet / screw pockets in the feet ───────────────────────────────────────
module gf_magnet_holes(nx, ny, screw = false) {
    for (i = [0 : nx - 1], j = [0 : ny - 1]) {
        cx = (i - (nx - 1) / 2) * GRID;
        cy = (j - (ny - 1) / 2) * GRID;
        for (sx = [-1, 1], sy = [-1, 1]) {
            translate([cx + sx * MAGNET_OFFSET, cy + sy * MAGNET_OFFSET, MAGNET_H])
                cylinder(d = MAGNET_D, h = MAGNET_H + 0.2, center = true);
            if (screw)
                translate([cx + sx * MAGNET_OFFSET, cy + sy * MAGNET_OFFSET, -0.1])
                    cylinder(d = SCREW_D, h = FOOT_H + 1);
        }
    }
}

// ── body (shell + cavity) ────────────────────────────────────────────────────
// returns the cavity (to be subtracted); h_u is in height units,
// the cavity floor sits 7 mm above the build plate
module gf_cavity(nx, ny, h_u, wall, floor, corner_r) {
    translate([0, 0, HEIGHT_U])
        linear_extrude(height = h_u * HEIGHT_U + 1)
            offset(r = -wall + corner_r)
                square([nx * GRID - TOL - 2 * corner_r, ny * GRID - TOL - 2 * corner_r], center = true);
}

// ── stacking lip ─────────────────────────────────────────────────────────────
module gf_lip(nx, ny, wall, top_z) {
    // perimeter rim: 0.7 up/out, 1.8 vertical, 1.9 in
    translate([0, 0, top_z])
        difference() {
            hull() {
                linear_extrude(height = 0.06)
                    offset(r = FOOT_R_TOP) square([nx * GRID - TOL - 2 * FOOT_R_TOP,
                                                   ny * GRID - TOL - 2 * FOOT_R_TOP], center = true);
                translate([0, 0, LIP_H - 0.06])
                    linear_extrude(height = 0.06)
                        offset(r = FOOT_R_TOP) square([nx * GRID - TOL - 2 * FOOT_R_TOP - 2 * (LIP_UP - LIP_LOW),
                                                       ny * GRID - TOL - 2 * FOOT_R_TOP - 2 * (LIP_UP - LIP_LOW)], center = true);
            }
            translate([0, 0, -1]) linear_extrude(height = LIP_H + 2)
                offset(r = -wall + FOOT_R_TOP)
                    square([nx * GRID - TOL - 2 * FOOT_R_TOP - 2 * wall,
                            ny * GRID - TOL - 2 * FOOT_R_TOP - 2 * wall], center = true);
        }
}

// ── hollow base ──────────────────────────────────────────────────────────────
// Real Gridfinity bins have hollow feet: only a thin shell, so you do not print
// ~140 g of solid plastic under a 4x4 tray. Subtracted from the base.
module gf_base_hollow(nx, ny, wall = WALL_DEF) {
    for (i = [0 : nx - 1], j = [0 : ny - 1])
        translate([(i - (nx - 1) / 2) * GRID, (j - (ny - 1) / 2) * GRID, -0.1])
            hull() {
                gf_slice(0, FOOT_INSET_BOTTOM + wall, FOOT_R_BOTTOM + wall, 0.06);
                gf_slice(FOOT_LOW, FOOT_INSET_VERT + wall, FOOT_R_VERT + wall, 0.06);
                gf_slice(FOOT_H - 0.06, FOOT_INSET_VERT + wall, FOOT_R_VERT + wall, 0.06);
            }
}

// ── internal divider grid ────────────────────────────────────────────────────
// Compartments are made by ADDING walls, not by cutting pockets into an open
// cavity: cutting into a cavity removes nothing (the space is already empty).
// px x py = number of compartments; h = divider height above the cavity floor.
module gf_dividers(nx, ny, px, py, h, wall = 1.2, grip = 0) {
    inner_x = nx * GRID - TOL - 2 * WALL_DEF;
    inner_y = ny * GRID - TOL - 2 * WALL_DEF;
    for (i = [1 : px - 1]) {
        x = -inner_x / 2 + inner_x * i / px;
        translate([x - wall / 2, -inner_y / 2, HEIGHT_U]) cube([wall, inner_y, h]);
        // grip notch so a part can be pinched out
        if (grip > 0)
            translate([x - wall / 2 - 0.01, 0, HEIGHT_U + h * 0.45])
                cube([wall + 0.02, grip, h * 0.55]);
    }
    for (j = [1 : py - 1]) {
        y = -inner_y / 2 + inner_y * j / py;
        translate([-inner_x / 2, y - wall / 2, HEIGHT_U]) cube([inner_x, wall, h]);
        if (grip > 0)
            translate([0, y - wall / 2 - 0.01, HEIGHT_U + h * 0.45])
                cube([grip, wall + 0.02, h * 0.55]);
    }
}

// ── fitted frame (holder for a bulky item) ───────────────────────────────────
// Walls ADDED around a part lying on the cavity floor, so it cannot slide.
// (Same lesson as with dividers: a subtracted "pocket" inside an open cavity
// removes nothing.) clear = clearance per side, wall = frame thickness,
// h = frame height above the floor, finger = grip gap across the middle.
module gf_frame(l, w, h, clear = 1.5, wall = 2.0, finger = 0, r = 2.0) {
    outer_l = l + 2 * clear + 2 * wall;
    outer_w = w + 2 * clear + 2 * wall;
    translate([0, 0, HEIGHT_U])
        difference() {
            linear_extrude(height = h)
                offset(r = r) square([outer_l - 2 * r, outer_w - 2 * r], center = true);
            translate([0, 0, -0.1]) linear_extrude(height = h + 0.2)
                offset(r = r) square([l + 2 * clear - 2 * r, w + 2 * clear - 2 * r], center = true);
            if (finger > 0)
                translate([-outer_l / 2 - 0.1, -finger / 2, -0.1])
                    cube([outer_l + 0.2, finger, h + 0.2]);
        }
}

// ── main module: tray / bin ──────────────────────────────────────────────────
module gf_tray(nx, ny, h_u,
               wall = WALL_DEF, floor = FLOOR_DEF,
               lip = true, magnets = false, screws = false,
               hollow_base = true,
               corner_r = FOOT_R_TOP) {
    difference() {
        union() {
            // feet, then the bridge plate that becomes the cavity floor
            // (spec: the 7 mm base = 4.75 mm foot profile + 2.25 mm bridge, NOT a solid slab)
            gf_feet(nx, ny);
            translate([0, 0, FOOT_H])
                linear_extrude(height = HEIGHT_U - FOOT_H)
                    offset(r = corner_r)
                        square([nx * GRID - TOL - 2 * corner_r, ny * GRID - TOL - 2 * corner_r], center = true);
            // walls
            translate([0, 0, HEIGHT_U])
                linear_extrude(height = h_u * HEIGHT_U - HEIGHT_U)
                    difference() {
                        offset(r = corner_r)
                            square([nx * GRID - TOL - 2 * corner_r, ny * GRID - TOL - 2 * corner_r], center = true);
                        offset(r = -wall + corner_r)
                            square([nx * GRID - TOL - 2 * corner_r - 2 * wall,
                                    ny * GRID - TOL - 2 * corner_r - 2 * wall], center = true);
                    }
            if (lip) gf_lip(nx, ny, wall, h_u * HEIGHT_U);
        }
        // cavity (floor is 7 mm above the build plate)
        gf_cavity(nx, ny, h_u, wall, floor, corner_r);
        if (hollow_base) gf_base_hollow(nx, ny, wall);
        if (magnets || screws) gf_magnet_holes(nx, ny, screws);
    }
}

// ── pockets ──────────────────────────────────────────────────────────────────
// rectangular pocket with a chamfered entry and an optional finger notch
module pocket_rect(l, w, h, clearance = 0.4, entry = 1.2, finger = 0, r = 1.5) {
    ll = l + clearance;
    ww = w + clearance;
    union() {
        hull() {
            translate([0, 0, h - entry]) linear_extrude(height = entry + 0.2)
                offset(r = r) square([ll - 2 * r, ww - 2 * r], center = true);
            translate([0, 0, h - entry - entry]) linear_extrude(height = 0.1)
                offset(r = r + entry) square([ll - 2 * r, ww - 2 * r], center = true);
        }
        translate([0, 0, -0.1]) linear_extrude(height = h - entry + 0.2)
            offset(r = r) square([ll - 2 * r, ww - 2 * r], center = true);
        if (finger > 0)
            translate([0, ww / 2 + finger / 2 - 0.01, h / 2])
                cube([ll * 0.6, finger, h], center = true);
    }
}

// channel for a beam lying flat, with an optional finger notch
module pocket_channel(l, w, h, clearance = 0.4, finger = 0) {
    pocket_rect(l, w, h, clearance = clearance, finger = finger);
}

// grid of small pockets (pins, shafts, standoffs)
module pocket_grid(nx, ny, d, h, pitch = 12.7, clearance = 0.35, r = 0) {
    for (i = [0 : nx - 1], j = [0 : ny - 1])
        translate([(i - (nx - 1) / 2) * pitch, (j - (ny - 1) / 2) * pitch, 0])
            cylinder(d = d + clearance, h = h + 0.2);
}

// ── labels ───────────────────────────────────────────────────────────────────
module label_text(txt, size = 4.5, depth = 0.6, font = "Liberation Sans:style=Bold") {
    translate([0, 0, -depth]) linear_extrude(height = depth + 0.01) text(txt, size = size, halign = "center", valign = "center");
}
