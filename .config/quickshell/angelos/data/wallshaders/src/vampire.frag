#version 440
// TrollOS «Vampire» (макет «Готика»): полная луна в рваных облаках над готическим замком,
// в окнах тлеет свет, у подножия ползёт туман, мимо луны пролетают летучие мыши.
// Тот же интерфейс, что у nebula.frag: time (с), size (px), glow (0..1 — луна вспыхивает).
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    vec2 size;
    float glow;
};

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}
float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}
float fbm(vec2 p) {
    float v = 0.0, a = 0.5;
    mat2 m = mat2(1.6, 1.2, -1.2, 1.6);
    for (int i = 0; i < 5; i++) {
        v += a * noise(p);
        p = m * p;
        a *= 0.5;
    }
    return v;
}

// a tower: a box up to h, a pointed roof of `roof` above it (y up)
float tower(vec2 p, float x, float w, float h, float roof) {
    float dx = abs(p.x - x);
    if (dx > w)
        return 0.0;
    if (p.y < h)
        return 1.0;
    return step(p.y, h + roof * (1.0 - dx / w));
}
// lit windows of a tower: a few cells glow, each breathes on its own
float windows(vec2 p, float x, float w, float h, float t) {
    vec2 g = vec2((p.x - x + w) / (w * 2.0) * 3.0, (p.y + 0.5) * 38.0);
    vec2 id = floor(g), f = fract(g);
    if (id.x < 0.0 || id.x > 2.0 || p.y > h - 0.02 || p.y < -0.40)
        return 0.0;
    float lit = step(0.78, hash(id + x * 17.0));
    float cell = step(0.32, f.x) * step(f.x, 0.68) * step(0.25, f.y) * step(f.y, 0.75);
    return lit * cell * (0.75 + 0.25 * sin(t * (0.8 + hash(id + 3.0)) + hash(id) * 6.28));
}
// the castle on its hill: 1 inside the silhouette; `win` gets the lit windows
float castle(vec2 p, float t, out float win) {
    float s = 0.0;
    win = 0.0;
    s = max(s, tower(p, 0.30, 0.034, -0.22, 0.10));
    s = max(s, tower(p, 0.39, 0.048, -0.12, 0.16));
    s = max(s, tower(p, 0.47, 0.030, -0.04, 0.13));
    s = max(s, tower(p, 0.555, 0.044, -0.15, 0.14));
    s = max(s, tower(p, 0.64, 0.030, -0.25, 0.09));
    // the walls between them, with battlements
    if (p.x > 0.26 && p.x < 0.68) {
        float top = -0.31 + 0.012 * step(0.5, fract(p.x * 55.0));
        s = max(s, step(p.y, top));
    }
    // a cross on the spire
    float cx = abs(p.x - 0.47);
    s = max(s, step(cx, 0.0032) * step(0.09, p.y) * step(p.y, 0.135));
    s = max(s, step(abs(p.y - 0.118), 0.0032) * step(cx, 0.013));
    win += windows(p, 0.39, 0.048, -0.12, t);
    win += windows(p, 0.47, 0.030, -0.04, t + 2.0);
    win += windows(p, 0.555, 0.044, -0.15, t + 4.0);
    return s;
}
// a bat flying across: 1 inside its silhouette
float bat(vec2 p, float i, float t, float aspect) {
    float T = 16.0 + 9.0 * hash(vec2(i, 1.0));
    float ph = fract((t + 37.0 * hash(vec2(i, 2.0))) / T);
    float dir = hash(vec2(i, 3.0)) > 0.5 ? 1.0 : -1.0;
    float x = dir * mix(-0.65 * aspect, 0.65 * aspect, ph);
    float y = -0.05 + 0.32 * hash(vec2(i, 4.0)) + 0.035 * sin(ph * 18.0 + i * 3.0);
    float s = 0.010 + 0.014 * hash(vec2(i, 5.0));
    vec2 q = (p - vec2(x, y)) / s;
    q.x *= dir;
    float flap = sin(t * (11.0 + 4.0 * hash(vec2(i, 6.0))) + i * 7.0);
    float body = step(length(q * vec2(1.7, 1.0)), 0.42);
    float ax = abs(q.x);
    float wy = flap * 0.55 * (ax - 0.25);
    float wing = step(0.2, ax) * step(ax, 1.5) * step(q.y, wy + 0.14) * step(wy - 0.30 * (1.55 - ax) + 0.07 * abs(sin(ax * 7.0)), q.y);
    float ears = step(abs(q.x) - 0.08, 0.12) * step(0.3, q.y) * step(q.y, 0.58) * step(0.07, abs(q.x));
    return max(body, max(wing, ears));
}

void main() {
    float aspect = size.x / size.y;
    vec2 uv = qt_TexCoord0;
    vec2 p = vec2((uv.x - 0.5) * aspect, 0.5 - uv.y);   // y up
    float t = time;

    // ── the sky: near-black above, a wine haze toward the horizon ──
    vec3 col = mix(vec3(0.20, 0.035, 0.11), vec3(0.018, 0.012, 0.03), smoothstep(-0.45, 0.35, p.y));
    col += vec3(0.08, 0.03, 0.10) * fbm(p * 2.0 + vec2(t * 0.004, 0.0)) * 0.6;

    // stars, fewer near the horizon
    vec2 g = p * 70.0;
    vec2 id = floor(g), f = fract(g) - 0.5;
    float h = hash(id);
    if (h < 0.10) {
        vec2 off = vec2(hash(id + 7.1), hash(id + 3.3)) - 0.5;
        float d = length(f - off * 0.7);
        float tw = 0.6 + 0.4 * sin(t * (1.0 + 2.0 * hash(id + 1.7)) + 6.28 * hash(id + 9.2));
        col += vec3(0.85, 0.82, 0.95) * smoothstep(0.09, 0.0, d) * tw * smoothstep(-0.25, 0.2, p.y) * 0.8;
    }

    // ── the moon ──
    vec2 mc = vec2(-0.42 * aspect / 1.78, 0.20);
    float mr = 0.115;
    float md = length(p - mc);
    float breathe = 0.92 + 0.08 * sin(t * 0.35) + 0.6 * glow;
    col += vec3(0.55, 0.45, 0.75) * exp(-max(md - mr, 0.0) * 9.0) * 0.30 * breathe;
    col += vec3(0.80, 0.55, 0.85) * exp(-max(md - mr, 0.0) * 40.0) * 0.25 * breathe;
    if (md < mr) {
        vec2 mq = (p - mc) / mr;
        float crater = fbm(mq * 3.2 + 4.0) * 0.55 + fbm(mq * 9.0) * 0.25;
        float limb = sqrt(max(0.0, 1.0 - dot(mq, mq)));
        vec3 moon = mix(vec3(0.62, 0.58, 0.70), vec3(0.95, 0.93, 0.98), smoothstep(0.30, 0.65, crater));
        moon *= 0.72 + 0.28 * limb;
        col = mix(col, moon, smoothstep(mr, mr - 0.002, md));
    }

    // ── clouds drifting over the moon: dark, their edges moonlit ──
    float cl = fbm(vec2(p.x * 1.6 + t * 0.012, p.y * 5.0 - 0.6) + fbm(p * 3.0 + t * 0.006));
    float cloud = smoothstep(0.50, 0.66, cl) * smoothstep(0.02, 0.14, p.y) * smoothstep(0.42, 0.22, p.y);
    float rim = exp(-md * 5.0);
    vec3 cloudCol = mix(vec3(0.05, 0.03, 0.07), vec3(0.42, 0.36, 0.52), rim * smoothstep(0.72, 0.55, cl));
    col = mix(col, cloudCol, cloud * 0.85);

    // ── bats ──
    float bats = 0.0;
    for (int i = 0; i < 6; i++)
        bats = max(bats, bat(p, float(i), t, aspect));
    col = mix(col, vec3(0.012, 0.006, 0.016), bats);

    // ── the hill and the castle, black against the haze ──
    float hill = step(p.y, -0.40 + 0.035 * sin(p.x * 2.4 + 0.6) + 0.02 * fbm(vec2(p.x * 6.0, 1.0)));
    float win;
    float c = max(castle(p, t, win), hill);
    col = mix(col, vec3(0.016, 0.010, 0.022), c);
    col += vec3(1.0, 0.45, 0.25) * win * 0.85;

    // ── fog crawling over the foot of the hill ──
    float fg = fbm(vec2(p.x * 1.3 - t * 0.025, p.y * 3.5 + t * 0.008));
    float fg2 = fbm(vec2(p.x * 2.6 + t * 0.018, p.y * 6.0 - 3.0));
    float fogA = smoothstep(-0.12, -0.50, p.y) * (0.25 + 0.75 * fg) * 0.75 + smoothstep(-0.30, -0.52, p.y) * fg2 * 0.35;
    col = mix(col, vec3(0.20, 0.15, 0.26), clamp(fogA, 0.0, 0.85));

    // vignette and grain
    col *= 1.0 - 0.50 * smoothstep(0.40, 1.10, length(p * vec2(0.8, 1.0)));
    col += (hash(uv * size + fract(t)) - 0.5) / 255.0 * 2.0;
    fragColor = vec4(col, 1.0) * qt_Opacity;
}
