#version 440
// The stone behind a hell bar (widgets/HellSlab), in art pixels: Voronoi cracks with
// something burning in them, stepped `time` so it flickers like pixel art.
//   kind 0 lava      obsidian, wide cracks of glowing lava that pulse (the taskbar, the dock)
//   kind 1 stone     dark rock, thin ember veins (the top strip)
//   kind 2 brimstone rock crusted with sulphur, a few hot cracks (the island)
//   kind 3 tomb      grey tombstone, dark hairline cracks, no glow (the capsules)
//   kind 4 blood     Hellose: black, a blood-red check, nothing cracked
// bevel: a lighter top-left and a darker bottom-right pixel row, an ink outline.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    float kind;
    float seed;
    float bevel;
    vec2 cells;     // the slab in art pixels
};

vec2 hash2(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3))) + seed;
    return fract(sin(p) * 43758.5453);
}
float hash(vec2 p) {
    return fract(sin(dot(p + seed * 1.7, vec2(12.9898, 78.233))) * 43758.5453);
}
// distance to the nearest crack (F2 − F1) and the id of the nearest cell
vec2 voronoi(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float d1 = 8.0, d2 = 8.0, id = 0.0;
    for (int y = -1; y <= 1; y++)
        for (int x = -1; x <= 1; x++) {
            vec2 g = vec2(float(x), float(y));
            vec2 o = hash2(i + g);
            float d = length(g + o - f);
            if (d < d1) {
                d2 = d1;
                d1 = d;
                id = hash(i + g);
            } else if (d < d2) {
                d2 = d;
            }
        }
    return vec2(d2 - d1, id);
}

void main() {
    vec2 cell = floor(qt_TexCoord0 * cells);
    float t = floor(time * 6.0) / 6.0;
    int k = int(kind + 0.5);
    float grain = hash(cell) - 0.5;
    vec3 col;

    if (k == 4) {
        // Hellose: black with a blood check, 4 art pixels a square
        bool on = mod(floor(cell.x / 4.0) + floor(cell.y / 4.0), 2.0) < 1.0;
        col = on ? vec3(0.09, 0.012, 0.025) : vec3(0.035, 0.006, 0.012);
        col += grain * 0.012;
    } else {
        float scale = k == 0 ? 12.0 : k == 1 ? 9.0 : k == 2 ? 10.0 : 9.0;
        vec2 v = voronoi(cell / scale);
        float edge = v.x;
        vec3 rock = k == 0 ? vec3(0.05, 0.016, 0.024) : k == 1 ? vec3(0.11, 0.07, 0.07) : k == 2 ? vec3(0.15, 0.1, 0.06) : vec3(0.36, 0.34, 0.37);
        col = rock * (1.0 + grain * (k == 3 ? 0.18 : 0.35));
        if (k == 2) {
            // sulphur crusts: whole Voronoi cells, some of them
            // sulphur crusts: some cells, speckled, near their middle only
            if (v.y > 0.8 && v.x > 0.22 && hash(cell * 1.7) > 0.35)
                col = mix(col, vec3(0.78, 0.66, 0.16), 0.35 + grain * 0.3);
        }
        if (k == 3) {
            // moss of soot in the lower part, weathered
            col *= 1.0 - smoothstep(0.55, 1.0, qt_TexCoord0.y) * 0.25;
        }
        float w = k == 0 ? 0.075 : k == 1 ? 0.05 : k == 2 ? 0.06 : 0.06;
        float crack = 1.0 - smoothstep(0.0, w, edge);
        if (k == 3) {
            col = mix(col, vec3(0.12, 0.11, 0.13), step(0.5, crack));
        } else {
            // mostly a dull red glow; the hot middle of a crack breathes, cell by cell
            float pulse = 0.6 + 0.4 * sin(t * 2.2 + v.y * 6.283);
            vec3 hot = mix(vec3(0.42, 0.04, 0.06), vec3(0.85, 0.22, 0.07), pulse);
            hot = mix(hot, vec3(1.0, 0.55, 0.16), step(0.8, crack) * pulse * (k == 0 ? 0.8 : 0.4));
            col = mix(col, hot, step(0.4, crack));
        }
    }
    if (bevel > 0.5) {
        if (cell.y < 1.0 || cell.x < 1.0)
            col = mix(col, vec3(1.0), k == 3 ? 0.18 : 0.08);
        if (cell.y > cells.y - 2.0 || cell.x > cells.x - 2.0)
            col *= 0.6;
    }
    fragColor = vec4(col, 1.0) * qt_Opacity;
}
