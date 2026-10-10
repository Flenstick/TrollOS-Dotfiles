#version 440
// Pixel transition between two wallpapers.
// style: 0 mosaic + ordered dither, 1 mosaic only, 2 dither only, 3 heart iris,
//        4 old TV (collapse to a line and back), 5 blinds, 6 diamonds (Win98),
//        7 glitch, 8 melt (DOOM), 9 sparkle dissolve, 10 dithered wipe
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    float maxBlock;
    float style;
    vec2 resolution;
    vec4 accent;
};

layout(binding = 1) uniform sampler2D fromTex;
layout(binding = 2) uniform sampler2D toTex;

// ordered dither threshold without arrays (works on every GLSL profile)
float bayer2(vec2 a) {
    a = floor(a);
    return fract(a.x / 2.0 + a.y * a.y * 0.75);
}
float bayer4(vec2 a) {
    return bayer2(0.5 * a) * 0.25 + bayer2(a);
}
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}
// heart curve: <= 0 inside
float heart(vec2 q) {
    float a = q.x * q.x + q.y * q.y - 1.0;
    return a * a * a - q.x * q.x * q.y * q.y * q.y;
}
vec4 pick(vec2 uv, float t) {
    return mix(texture(fromTex, uv), texture(toTex, uv), t);
}

void main() {
    float p = clamp(progress, 0.0, 1.0);
    vec2 uv = qt_TexCoord0;
    // at rest the picture is just the picture: no scanlines (old TV), leftover
    // sparkles or glitch bands once a transition is over — "random" picks a style
    // at startup, and it must not stay on screen
    if (p >= 1.0) {
        fragColor = texture(toTex, uv) * qt_Opacity;
        return;
    }
    if (p <= 0.0) {
        fragColor = texture(fromTex, uv) * qt_Opacity;
        return;
    }
    vec2 px = uv * resolution;
    vec4 outc;

    if (style < 2.5) {
        // block size grows to maxBlock at the middle and shrinks back, in power-of-two steps
        float bs = 1.0;
        if (style < 1.5) {
            float m = sin(p * 3.14159265);
            bs = exp2(floor(mix(0.0, log2(max(maxBlock, 1.0)), m * m) + 0.5));
        }
        vec2 cuv = (floor(px / bs) + 0.5) * bs / resolution;
        float t;
        if (style > 0.5 && style < 1.5) {
            t = step(0.5, p);
        } else {
            float dg = max(bs, 8.0);
            float th = bayer4(floor(px / dg));
            float q = smoothstep(0.12, 0.88, p);
            t = step(th, q);
        }
        outc = pick(cuv, t);
    } else if (style < 3.5) {
        // heart iris: grows from the middle, pixel edge with an accent rim
        float cs = 8.0;
        vec2 c = (floor(px / cs) + 0.5) * cs;
        float s = min(resolution.x, resolution.y);
        vec2 q = (c - resolution * 0.5) / s;
        q.y = -q.y + 0.08;
        float r = p * 1.35 + 0.0001;
        float inside = step(heart(q / r), 0.0);
        float inner = step(heart(q / (r * 0.94)), 0.0);
        outc = pick(uv, inside);
        if (inside > 0.5 && inner < 0.5 && p < 0.98)
            outc = vec4(accent.rgb, 1.0);
    } else if (style < 4.5) {
        // old TV: the picture folds into a bright line, the new one unfolds from it
        float h = p < 0.5 ? 1.0 - p * 2.0 : (p - 0.5) * 2.0;
        h = max(h * h, 0.004);
        float dy = (uv.y - 0.5) / h;
        vec2 suv = vec2(0.5 + (uv.x - 0.5) / mix(0.2, 1.0, smoothstep(0.0, 0.3, h)), 0.5 + dy);
        vec4 img = p < 0.5 ? texture(fromTex, suv) : texture(toTex, suv);
        float on = step(abs(dy), 0.5) * step(abs(suv.x - 0.5), 0.5);
        float glow = (1.0 - h) * 1.6;
        float scan = 0.82 + 0.18 * step(0.5, fract(px.y / 3.0));
        outc = vec4((img.rgb + glow) * scan * on, 1.0);
    } else if (style < 5.5) {
        // blinds: horizontal slats turn one after another, top to bottom
        float slat = 36.0;
        float row = floor(px.y / slat);
        float n = resolution.y / slat;
        float t = clamp(p * 1.6 - row / n * 0.6, 0.0, 1.0);
        float within = floor(fract(px.y / slat) * slat / 4.0) * 4.0 / slat;
        outc = pick(uv, step(within, t - 0.001));
    } else if (style < 6.5) {
        // diamonds: a grid of diamonds grows left to right
        float cs = 48.0;
        vec2 cell = floor(px / cs);
        vec2 f = (floor(px / 4.0) * 4.0 + 2.0 - cell * cs) / cs - 0.5;
        float d = abs(f.x) + abs(f.y);
        float r = clamp(p * 2.2 - (cell.x * cs / resolution.x) * 1.2, 0.0, 1.05);
        outc = pick(uv, step(d, r));
    } else if (style < 7.5) {
        // glitch: slices jump sideways and split into RGB, each flips on its own
        float amt = sin(p * 3.14159265);
        float band = floor(px.y / 24.0);
        float rnd = hash(vec2(band, floor(p * 12.0)));
        float off = (rnd - 0.5) * 0.18 * amt * step(0.55, hash(vec2(band, 7.0 + floor(p * 9.0))));
        float t = step(hash(vec2(band, 3.0)) * 0.8 + 0.1, p);
        vec2 g = vec2(uv.x + off, uv.y);
        float sp = 0.012 * amt;
        vec4 cr = pick(g + vec2(sp, 0.0), t);
        vec4 cg = pick(g, t);
        vec4 cb = pick(g - vec2(sp, 0.0), t);
        outc = vec4(cr.r, cg.g, cb.b, 1.0);
        outc.rgb = mix(outc.rgb, accent.rgb, 0.25 * amt * step(0.93, hash(vec2(band, floor(p * 20.0)))));
    } else if (style < 8.5) {
        // melt: the old picture slides down in uneven columns, the new one is behind
        float col = floor(px.x / 8.0);
        float delay = hash(vec2(col, 1.0)) * 0.35;
        float k = clamp((p * 1.4 - delay) / 1.0, 0.0, 1.0);
        float drop = k * k * resolution.y * 1.05;
        float y = px.y - drop;
        if (y < 0.0)
            outc = texture(toTex, uv);
        else
            outc = texture(fromTex, vec2(uv.x, y / resolution.y));
    } else if (style < 9.5) {
        // sparkle dissolve: pixels flip at random, freshly flipped ones twinkle
        float cs = 6.0;
        vec2 cell = floor(px / cs);
        float r = hash(cell);
        float t = step(r, p * 1.1 - 0.05);
        outc = pick(uv, t);
        float fresh = step(p * 1.1 - 0.13, r) * t;
        vec2 f = fract(px / cs) - 0.5;
        float plus = step(min(abs(f.x), abs(f.y)), 0.17);
        outc.rgb = mix(outc.rgb, mix(accent.rgb, vec3(1.0), 0.45), fresh * plus);
    } else {
        // dithered wipe: left to right with a ragged pixel edge
        vec2 cell = floor(px / 12.0);
        float th = (cell.x * 12.0 / resolution.x) * 0.8 + bayer4(cell) * 0.2;
        outc = pick(uv, step(th, p));
    }
    fragColor = outc * qt_Opacity;
}
