// ─────────────────────────────────────────────────────────────────────────────
// gf.scad — Gridfinity základ dle otevřené spec (gridfinity.xyz)
// Čísla jsou ze spec a z referenční implementace gridfinity-rebuilt-openscad.
// Nic tady nezaokrouhluj "od oka" — když se změní číslo, změň i test v tests/test_gf_dims.py
// ─────────────────────────────────────────────────────────────────────────────

// mřížka a výšky
GRID        = 42.0;   // pitch buňky
HEIGHT_U    = 7.0;    // jedna výšková jednotka
TOL         = 0.5;    // bin = 42n - 0.5 (0.25 mm na stranu)

// nožička (foot), zdola nahoru: 45° / svisle / 45°
FOOT_LOW    = 0.8;
FOOT_VERT   = 1.8;
FOOT_UP     = 2.15;   // součet = 4.75
FOOT_H      = FOOT_LOW + FOOT_VERT + FOOT_UP;
FOOT_INSET_BOTTOM = 3.2;   // 42 - 35.6
FOOT_INSET_VERT   = 2.4;   // 42 - 37.2
FOOT_INSET_TOP    = 0.25;  // 42 - 41.5
FOOT_R_BOTTOM = 0.8;
FOOT_R_VERT   = 1.6;
FOOT_R_TOP    = 3.75;

// stacking lip (nasednutí dalšího boxu), zdola nahoru: 0.7 / 1.8 / 1.9
LIP_LOW     = 0.7;
LIP_VERT    = 1.8;
LIP_UP      = 1.9;
LIP_H       = LIP_LOW + LIP_VERT + LIP_UP;   // 4.4

// magnety a šrouby
MAGNET_D      = 6.5;   // pro magnet ⌀6 × 2
MAGNET_H      = 2.4;
MAGNET_OFFSET = 13.0;  // od středu buňky
SCREW_D       = 3.2;   // M3

// stěny
WALL_DEF    = 1.2;
FLOOR_DEF   = 0.8;

$fn = 64;

// ── 2D profily ───────────────────────────────────────────────────────────────
// čtverec o straně 42-2*inset se zaoblenými rohy o poloměru r (vycentrovaný)
module gf_profile(inset, r) {
    offset(r = r) square([GRID - 2 * inset - 2 * r, GRID - 2 * inset - 2 * r], center = true);
}

// obdélníkový půdorys vnějšího těla (nx × ny buněk, mínus tolerance)
module body_profile(nx, ny, r = FOOT_R_TOP) {
    offset(r = r) square([nx * GRID - TOL - 2 * r, ny * GRID - TOL - 2 * r], center = true);
}

// tenká vrstva profilu (pomocník pro hull)
module gf_slice(z, inset, r, t = 0.06) {
    translate([0, 0, z]) linear_extrude(height = t) gf_profile(inset, r);
}

// ── nožička jedné buňky ──────────────────────────────────────────────────────
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

// ── magnety / šrouby do nožičky ──────────────────────────────────────────────
module gf_magnet_holes(nx, ny, screw = false) {
    for (i = [0 : nx - 1], j = [0 : ny - 1]) {
        cx = (i - (nx - 1) / 2) * GRID;
        cy = (j - (ny - 1) / 2) * GRID;
        for (sx = [-1, 1], sy = [-1, 1]) {
            translate([cx + sx * MAGNET_OFFSET / 2 * 2, cy + sy * MAGNET_OFFSET / 2 * 2, MAGNET_H])
                cylinder(d = MAGNET_D, h = MAGNET_H + 0.2, center = true);
            if (screw)
                translate([cx + sx * MAGNET_OFFSET, cy + sy * MAGNET_OFFSET, -0.1])
                    cylinder(d = SCREW_D, h = FOOT_H + 1);
        }
    }
}

// ── tělo (obálka + dutina) ───────────────────────────────────────────────────
// vrací dutinu (k odpočtu); výška h_u je v jednotkách, dno dutiny je v 7 mm
module gf_cavity(nx, ny, h_u, wall, floor, corner_r) {
    translate([0, 0, HEIGHT_U])
        linear_extrude(height = h_u * HEIGHT_U + 1)
            offset(r = -wall + corner_r)
                square([nx * GRID - TOL - 2 * corner_r, ny * GRID - TOL - 2 * corner_r], center = true);
}

// ── lip (nasednutí) ──────────────────────────────────────────────────────────
module gf_lip(nx, ny, wall, top_z) {
    // obvodový prstenec: 0.7 nahoru/ven, 1.8 svisle, 1.9 dovnitř
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

// ── hlavní modul: vložka / box ───────────────────────────────────────────────
module gf_tray(nx, ny, h_u,
               wall = WALL_DEF, floor = FLOOR_DEF,
               lip = true, magnets = false, screws = false,
               corner_r = FOOT_R_TOP) {
    difference() {
        union() {
            // nožičky + most (spodní část do 7 mm)
            gf_feet(nx, ny);
            linear_extrude(height = HEIGHT_U)
                offset(r = corner_r)
                    square([nx * GRID - TOL - 2 * corner_r, ny * GRID - TOL - 2 * corner_r], center = true);
            // stěny
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
        // dutina (dno je 7 mm nad podložkou)
        gf_cavity(nx, ny, h_u, wall, floor, corner_r);
        if (magnets || screws) gf_magnet_holes(nx, ny, screws);
    }
}

// ── kapsy (pockets) ──────────────────────────────────────────────────────────
// obdélníková kapsa se zkoseným vstupem a volitelným vybráním pro prst
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

// kanál na nosník (díl položený naplocho) s nehtem na vytažení
module pocket_channel(l, w, h, clearance = 0.4, finger = 0) {
    pocket_rect(l, w, h, clearance = clearance, finger = finger);
}

// mřížka malých kapes (piny, osičky, kolíky)
module pocket_grid(nx, ny, d, h, pitch = 12.7, clearance = 0.35, r = 0) {
    for (i = [0 : nx - 1], j = [0 : ny - 1])
        translate([(i - (nx - 1) / 2) * pitch, (j - (ny - 1) / 2) * pitch, 0])
            cylinder(d = d + clearance, h = h + 0.2);
}

// ── popisky ──────────────────────────────────────────────────────────────────
module label_text(txt, size = 4.5, depth = 0.6, font = "Liberation Sans:style=Bold") {
    translate([0, 0, -depth]) linear_extrude(height = depth + 0.01) text(txt, size = size, halign = "center", valign = "center");
}
