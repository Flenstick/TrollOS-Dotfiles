#version 440
// TrollOS «Void» (макет «Минимал»): почти чёрная пустота, тонкая пыль и звёзды в три слоя
// медленно плывут с параллаксом; изредка падает звезда. Дёшево: без fbm на каждый слой.
// Тот же интерфейс, что у nebula.frag: time (с), size (px), glow (0..1 — звёзды ярче).
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
float seg(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}
// one layer of stars; px = how big one screen pixel is in p units
float stars(vec2 p, float scale, float density, float t, float px) {
    vec2 g = p * scale;
    vec2 id = floor(g), f = fract(g) - 0.5;
    float h = hash(id);
    if (h > density)
        return 0.0;
    vec2 off = vec2(hash(id + 7.1), hash(id + 3.3)) - 0.5;
    float d = length(f - off * 0.7) / scale;           // back to p units
    float r = px * (0.8 + 1.4 * hash(id + 5.5));
    float tw = 0.65 + 0.35 * sin(t * (0.4 + 1.2 * hash(id + 1.7)) + 6.28 * hash(id + 9.2));
    return (smoothstep(r, 0.0, d) + smoothstep(r * 5.0, 0.0, d) * 0.06) * tw;
}

void main() {
    float aspect = size.x / size.y;
    vec2 uv = qt_TexCoord0;
    vec2 p = (uv - 0.5) * vec2(aspect, 1.0);
    float t = time;
    float px = 1.0 / size.y;
    vec2 drift = vec2(1.0, 0.35) * t;

    // the void, a breath lighter toward the middle; a faint cold dust across it
    vec3 col = vec3(0.020, 0.021, 0.024) * (1.0 - 0.6 * length(p));
    float dust = noise(p * 2.2 + drift * 0.002) * 0.6 + noise(p * 5.0 - drift * 0.003) * 0.4;
    col += vec3(0.020, 0.026, 0.036) * smoothstep(0.45, 0.95, dust);

    // three layers, the near ones faster
    float s = 0.0;
    s += stars(p + drift * 0.0015, 30.0, 0.10, t, px) * 0.95;
    s += stars(p + 11.3 + drift * 0.0008, 60.0, 0.08, t * 1.2, px) * 0.55;
    s += stars(p + 4.7 + drift * 0.0004, 120.0, 0.06, t * 1.4, px) * 0.32;
    col += vec3(0.86, 0.89, 0.95) * s * (1.0 + glow);

    // a falling star every ~31 s
    float mp = 31.0;
    float mi = floor((t + 14.0) / mp), mt = fract((t + 14.0) / mp) * mp;   // not in the first frame (the still)
    if (mt < 0.9) {
        vec2 a = vec2((hash(vec2(mi, 1.0)) - 0.5) * aspect, -0.45 + 0.25 * hash(vec2(mi, 2.0)));
        vec2 dir = normalize(vec2(hash(vec2(mi, 3.0)) - 0.5, 0.5));
        vec2 head = a + dir * mt * 0.8;
        float md = seg(p, head - dir * 0.14, head);
        float along = clamp(dot(p - (head - dir * 0.14), dir) / 0.14, 0.0, 1.0);
        col += vec3(0.9, 0.93, 1.0) * smoothstep(px * 1.5, 0.0, md) * along * (1.0 - mt / 0.9);
    }

    col += (hash(uv * size + fract(t)) - 0.5) / 255.0 * 1.5;
    fragColor = vec4(col, 1.0) * qt_Opacity;
}
