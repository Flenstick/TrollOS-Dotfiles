#version 440
// Hell's ground in art pixels (widgets/HellTexture): one of a few patterns, coloured by the
// circle (story/circles.json, "bar"), ordered-dithered like pixel art. Still: nothing moves
// unless `time` does (a circle's rare event), so a static bar costs nothing after its frame.
//   kind 0 stone   Voronoi slabs, cracks, a faint light deep in them
//   kind 1 ash     fine grey grain, a few flecks
//   kind 2 water   slow horizontal swell, dark bands
//   kind 3 ice     facets with straight bright cracks
//   kind 4 iron    riveted plates with seams
//   kind 5 sand    diagonal drifts, grains (a few hot ones)
//   kind 6 pitch   near black, a sheen here and there
//   kind 7 whirl   spiral bands around the middle
// colors: c0 the ground, c1 the grain / second tone, c2 the lines, c3 the light.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 cells;     // the area in art pixels
    float kind;
    float grid;     // the pattern's size, in art pixels (QML: "scale" is an Item property)
    float crack;    // 0..1: how much the lines show
    float glow;     // 0..1: how much light is in them
    float seed;
    float time;
    vec4 c0;
    vec4 c1;
    vec4 c2;
    vec4 c3;
};

float hash(vec2 p) {
    return fract(sin(dot(p + seed * 1.37, vec2(12.9898, 78.233))) * 43758.5453);
}
vec2 hash2(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3))) + seed;
    return fract(sin(p) * 43758.5453);
}
float vnoise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i), b = hash(i + vec2(1.0, 0.0)), c = hash(i + vec2(0.0, 1.0)), d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}
// F2 - F1 (distance to the nearest edge) and the id of the nearest cell
vec2 voronoi(vec2 p) {
    vec2 i = floor(p), f = fract(p);
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
            } else if (d < d2)
                d2 = d;
        }
    return vec2(d2 - d1, id);
}
// 4×4 Bayer threshold for the art pixel: blends become dither, never smooth gradients
float bayer(vec2 c) {
    int x = int(mod(c.x, 4.0)), y = int(mod(c.y, 4.0));
    int i = x + y * 4;
    float m = 0.0;
    if (i == 0) m = 0.0; else if (i == 1) m = 8.0; else if (i == 2) m = 2.0; else if (i == 3) m = 10.0;
    else if (i == 4) m = 12.0; else if (i == 5) m = 4.0; else if (i == 6) m = 14.0; else if (i == 7) m = 6.0;
    else if (i == 8) m = 3.0; else if (i == 9) m = 11.0; else if (i == 10) m = 1.0; else if (i == 11) m = 9.0;
    else if (i == 12) m = 15.0; else if (i == 13) m = 7.0; else if (i == 14) m = 13.0; else m = 5.0;
    return (m + 0.5) / 16.0;
}
vec3 dither(vec3 a, vec3 b, float t, vec2 cell) {
    return t > bayer(cell) ? b : a;
}

void main() {
    vec2 cell = floor(qt_TexCoord0 * cells);
    int k = int(kind + 0.5);
    float s = max(2.0, grid);
    vec3 col = c0.rgb;
    float grain = vnoise(cell / (s * 0.6));

    if (k == 0) {
        vec2 v = voronoi(cell / s);
        col = dither(c0.rgb, c1.rgb, grain * 0.7 + v.y * 0.3, cell);
        float w = 0.025 + 0.07 * crack;
        if (v.x < w)
            col = c2.rgb;
        if (glow > 0.0 && v.x < w * 0.45 && hash(floor(cell / 3.0)) < glow)
            col = c3.rgb;
    } else if (k == 1) {
        col = dither(c0.rgb, c1.rgb, grain * 0.85, cell);
        float h = hash(cell);
        if (h > 1.0 - 0.03 * crack)
            col = c2.rgb;
        else if (h < 0.004 * glow)
            col = c3.rgb;
    } else if (k == 2) {
        float swell = sin((cell.y + vnoise(vec2(cell.x / s, seed)) * s * 0.6) / (s * 0.35));
        col = dither(c0.rgb, c1.rgb, swell * 0.5 + 0.35, cell);
        if (abs(swell) > 0.985 && hash(cell) < crack)
            col = c2.rgb;
        if (swell > 0.97 && hash(cell + 7.0) < 0.12 * glow)
            col = c3.rgb;
    } else if (k == 3) {
        vec2 v = voronoi(cell / (s * 1.4));
        col = dither(c0.rgb, c1.rgb, v.y * 0.8 + grain * 0.2, cell);
        float w = 0.015 + 0.05 * crack;
        if (v.x < w)
            col = c2.rgb;
        if (v.x < w && hash(floor(cell / 2.0)) < 0.08 * glow)
            col = c3.rgb;
    } else if (k == 4) {
        vec2 plate = vec2(floor(s * 1.6), floor(s * 0.8));
        vec2 p = mod(cell, plate);
        col = dither(c0.rgb, c1.rgb, vnoise(vec2(cell.x / 2.0, cell.y / (s * 2.0))) * 0.8, cell);
        if (p.x < 1.0 || p.y < 1.0)
            col = mix(col, c2.rgb, crack > 0.0 ? 1.0 : 0.0);
        if ((p.x == 2.0 || p.x == plate.x - 2.0) && (p.y == 2.0 || p.y == plate.y - 2.0))
            col = glow > 0.0 ? c3.rgb : c2.rgb;
    } else if (k == 5) {
        float drift = fract((cell.x + cell.y * 2.0) / (s * 1.2) + vnoise(cell / s) * 0.6);
        col = dither(c0.rgb, c1.rgb, drift, cell);
        float h = hash(cell);
        if (h > 1.0 - 0.05 * crack)
            col = c2.rgb;
        else if (h < 0.01 * glow)
            col = c3.rgb;
    } else if (k == 6) {
        col = c0.rgb;
        float sheen = vnoise(vec2(cell.x / (s * 3.0), cell.y / s));
        if (sheen > 0.78)
            col = dither(c0.rgb, c1.rgb, (sheen - 0.78) * 3.0, cell);
        if (hash(floor(cell / 2.0)) < 0.006 * crack)
            col = c2.rgb;
    } else {
        vec2 mid = cells * 0.5;
        vec2 d = cell - mid;
        float a = atan(d.y, d.x * 0.35);
        float r = length(vec2(d.x * 0.35, d.y));
        float band = sin(a * 3.0 + r / s * 2.2 + seed);
        col = dither(c0.rgb, c1.rgb, band * 0.5 + 0.3, cell);
        if (abs(band) < 0.04 + 0.08 * crack)
            col = c2.rgb;
    }
    fragColor = vec4(col, 1.0) * qt_Opacity;
}
