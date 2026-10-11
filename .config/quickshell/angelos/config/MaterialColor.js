.pragma library
// TrollOS: Material You colour (the «Material You» desktop look, Settings → Material You).
// From one seed colour: tonal palettes and the Material 3 scheme roles (primary, surface
// containers, outline …), light or dark, in the variants Android offers. Tones are CIELAB L*
// — what HCT's tone is — at the palette's hue and chroma, the chroma cut back to what sRGB
// can show at that tone. Close to material-color-utilities, small enough for the shell.
//   scheme(seed, variant, dark) -> {primary, onPrimary, primaryContainer, …, palettes}
//   variants: tonalSpot (Android's default) | vibrant | expressive | neutral | monochrome | fidelity

// ---- sRGB <-> CIELAB (D65) ----
function hexRgb(h) {
    h = String(h).replace("#", "");
    if (h.length === 3)
        h = h.split("").map(c => c + c).join("");
    return [parseInt(h.slice(0, 2), 16) / 255, parseInt(h.slice(2, 4), 16) / 255, parseInt(h.slice(4, 6), 16) / 255];
}
function rgbHex(r, g, b) {
    const c = v => {
        const n = Math.max(0, Math.min(255, Math.round(v * 255)));
        return (n < 16 ? "0" : "") + n.toString(16);
    };
    return "#" + c(r) + c(g) + c(b);
}
function lin(c) {
    return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
}
function delin(c) {
    return c <= 0.0031308 ? 12.92 * c : 1.055 * Math.pow(c, 1 / 2.4) - 0.055;
}
const WX = 0.95047, WY = 1.0, WZ = 1.08883;
function labF(t) {
    return t > 216 / 24389 ? Math.cbrt(t) : (24389 / 27 * t + 16) / 116;
}
function labFi(t) {
    return t * t * t > 216 / 24389 ? t * t * t : (116 * t - 16) / (24389 / 27);
}
function rgbLab(rgb) {
    const r = lin(rgb[0]), g = lin(rgb[1]), b = lin(rgb[2]);
    const x = (0.4124 * r + 0.3576 * g + 0.1805 * b) / WX;
    const y = (0.2126 * r + 0.7152 * g + 0.0722 * b) / WY;
    const z = (0.0193 * r + 0.1192 * g + 0.9505 * b) / WZ;
    const fx = labF(x), fy = labF(y), fz = labF(z);
    return [116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz)];
}
// L*, chroma, hue (degrees) -> linear-free sRGB, or null when out of gamut
function lchRgb(L, C, H) {
    const a = C * Math.cos(H * Math.PI / 180), b = C * Math.sin(H * Math.PI / 180);
    const fy = (L + 16) / 116, fx = fy + a / 500, fz = fy - b / 200;
    const x = labFi(fx) * WX, y = (L > 8 ? fy * fy * fy : L / (24389 / 27)) * WY, z = labFi(fz) * WZ;
    const r = 3.2406 * x - 1.5372 * y - 0.4986 * z;
    const g = -0.9689 * x + 1.8758 * y + 0.0415 * z;
    const bl = 0.0557 * x - 0.2040 * y + 1.0570 * z;
    const e = 1e-4;
    if (r < -e || g < -e || bl < -e || r > 1 + e || g > 1 + e || bl > 1 + e)
        return null;
    return [delin(Math.max(0, r)), delin(Math.max(0, g)), delin(Math.max(0, bl))];
}
// the colour at tone T of a palette (hue H, chroma C): as much of C as fits at that tone
function tone(H, C, T) {
    if (T <= 0)
        return "#000000";
    if (T >= 100)
        return "#ffffff";
    let rgb = lchRgb(T, C, H);
    if (rgb)
        return rgbHex(rgb[0], rgb[1], rgb[2]);
    let lo = 0, hi = C;
    rgb = lchRgb(T, 0, H);
    for (let i = 0; i < 18; i++) {
        const mid = (lo + hi) / 2, m = lchRgb(T, mid, H);
        if (m) {
            lo = mid;
            rgb = m;
        } else {
            hi = mid;
        }
    }
    return rgbHex(rgb[0], rgb[1], rgb[2]);
}
function hct(hex) {
    const lab = rgbLab(hexRgb(hex));
    const C = Math.hypot(lab[1], lab[2]);
    let H = Math.atan2(lab[2], lab[1]) * 180 / Math.PI;
    if (H < 0)
        H += 360;
    return {
        "h": H,
        "c": C,
        "t": lab[0]
    };
}
function rot(h, d) {
    return ((h + d) % 360 + 360) % 360;
}
function palette(h, c) {
    return {
        "h": h,
        "c": c,
        "tone": t => tone(h, c, t)
    };
}

// ---- the variants: a palette each for primary, secondary, tertiary, neutral, neutral-variant ----
// (chromas are CIELAB's, a little above CAM16's numbers material-color-utilities uses)
function palettes(seed, variant) {
    const s = hct(seed);
    const h = s.h;
    switch (variant) {
    case "vibrant":
        return [palette(h, Math.max(s.c, 75)), palette(rot(h, 12), 30), palette(rot(h, 45), 40), palette(h, 12), palette(h, 16)];
    case "expressive":
        return [palette(rot(h, 240), 50), palette(rot(h, 15), 28), palette(rot(h, 120), 38), palette(rot(h, 15), 9), palette(rot(h, 15), 14)];
    case "neutral":
        return [palette(h, 14), palette(h, 8), palette(rot(h, 60), 18), palette(h, 3), palette(h, 6)];
    case "monochrome":
        return [palette(h, 0), palette(h, 0), palette(h, 0), palette(h, 0), palette(h, 0)];
    case "fidelity":
        return [palette(h, Math.max(s.c, 20)), palette(h, Math.max(s.c / 3, 14)), palette(rot(h, 60), Math.max(s.c / 2, 24)), palette(h, Math.max(s.c / 12, 4)), palette(h, Math.max(s.c / 8, 8))];
    default: // tonalSpot
        return [palette(h, 42), palette(h, 18), palette(rot(h, 60), 28), palette(h, 5), palette(h, 9)];
    }
}

// ---- the scheme: Material 3's colour roles ----
function scheme(seed, variant, dark) {
    const p = palettes(seed || "#6750a4", variant || "tonalSpot");
    const P = p[0], S = p[1], T = p[2], N = p[3], NV = p[4];
    const E = palette(25, 75), G = palette(140, 50), Y = palette(85, 60), B = palette(255, 45);
    const d = !!dark;
    const r = {
        "primary": P.tone(d ? 80 : 40),
        "onPrimary": P.tone(d ? 20 : 100),
        "primaryContainer": P.tone(d ? 30 : 90),
        "onPrimaryContainer": P.tone(d ? 90 : 10),
        "inversePrimary": P.tone(d ? 40 : 80),
        "secondary": S.tone(d ? 80 : 40),
        "onSecondary": S.tone(d ? 20 : 100),
        "secondaryContainer": S.tone(d ? 30 : 90),
        "onSecondaryContainer": S.tone(d ? 90 : 10),
        "tertiary": T.tone(d ? 80 : 40),
        "onTertiary": T.tone(d ? 20 : 100),
        "tertiaryContainer": T.tone(d ? 30 : 90),
        "onTertiaryContainer": T.tone(d ? 90 : 10),
        "error": E.tone(d ? 80 : 40),
        "onError": E.tone(d ? 20 : 100),
        "errorContainer": E.tone(d ? 30 : 90),
        "onErrorContainer": E.tone(d ? 90 : 10),
        "surface": N.tone(d ? 6 : 98),
        "surfaceDim": N.tone(d ? 6 : 87),
        "surfaceBright": N.tone(d ? 24 : 98),
        "surfaceContainerLowest": N.tone(d ? 4 : 100),
        "surfaceContainerLow": N.tone(d ? 10 : 96),
        "surfaceContainer": N.tone(d ? 12 : 94),
        "surfaceContainerHigh": N.tone(d ? 17 : 92),
        "surfaceContainerHighest": N.tone(d ? 22 : 90),
        "onSurface": N.tone(d ? 90 : 10),
        "onSurfaceVariant": NV.tone(d ? 80 : 30),
        "outline": NV.tone(d ? 60 : 50),
        "outlineVariant": NV.tone(d ? 30 : 80),
        "inverseSurface": N.tone(d ? 90 : 20),
        "inverseOnSurface": N.tone(d ? 20 : 95),
        "shadow": "#000000",
        "scrim": "#000000",
        "ok": G.tone(d ? 80 : 40),
        "dark": d,
        // for terminals: red, green, yellow, blue, magenta, cyan at a readable tone
        "ansi": [N.tone(d ? 12 : 90), E.tone(d ? 70 : 40), G.tone(d ? 70 : 40), Y.tone(d ? 75 : 45), B.tone(d ? 70 : 40), T.tone(d ? 70 : 40), palette(200, 35).tone(d ? 70 : 40), N.tone(d ? 85 : 25), N.tone(d ? 40 : 60), E.tone(d ? 80 : 50), G.tone(d ? 80 : 50), Y.tone(d ? 85 : 55), B.tone(d ? 80 : 50), T.tone(d ? 80 : 50), palette(200, 35).tone(d ? 80 : 50), N.tone(d ? 95 : 10)],
        // the palettes themselves (the icons are recoloured along the primary one)
        "hues": {
            "primary": [P.h, P.c],
            "secondary": [S.h, S.c],
            "tertiary": [T.h, T.c],
            "neutral": [N.h, N.c],
            "neutralVariant": [NV.h, NV.c]
        }
    };
    r.surfaceTint = r.primary;
    return r;
}

// what angelOS's palette needs (Theme.flavors' shape, `more` overriding the derived tones)
function flavor(seed, variant, dark) {
    const m = scheme(seed, variant, dark);
    return {
        "desk": m.surface,
        "face": m.surfaceContainer,
        "faceAlt": m.surfaceContainerHigh,
        "text": m.onSurface,
        "textDim": m.onSurfaceVariant,
        "accent": m.primary,
        "accent2": m.tertiary,
        "title1": m.primaryContainer,
        "title2": m.secondaryContainer,
        "more": {
            "sunken": m.surfaceContainerLowest,
            "hi": m.surfaceContainerHighest,
            "lo": m.surfaceDim,
            "edge": m.outlineVariant,
            "accent3": m.secondary,
            "accent4": m.tertiary,
            "danger": m.error,
            "ok": m.ok,
            "selectText": m.onPrimary,
            "shadow": "#000000",
            "ansi": m.ansi
        }
    };
}

// a tone of the primary palette, for the icons: the seed's hue at tone t
function primaryTone(seed, variant, t) {
    return palettes(seed, variant)[0].tone(t);
}

// a seed from a picture's colours (services pick the most colourful well-lit one)
function seedScore(hex) {
    const s = hct(hex);
    return s.c * (1 - Math.abs(s.t - 55) / 60);
}
