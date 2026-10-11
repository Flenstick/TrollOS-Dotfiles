#version 440
// «Адская туманность» (плагин hell-nebula): красный космос — туманность клубится
// (domain-warped fbm), звёзды мерцают, по центру перевёрнутая пентаграмма-созвездие:
// пять ярких звёзд, тонкие линии между ними, по линиям бежит искра; изредка — метеор.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;      // секунды
    vec2 size;       // размер в пикселях
    float glow;      // 0..1 — вспышка созвездия (призыв)
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
    for (int i = 0; i < 6; i++) {
        v += a * noise(p);
        p = m * p;
        a *= 0.5;
    }
    return v;
}
float seg(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}
// вершина i перевёрнутой пентаграммы (i=0 — вниз; ось y вниз) и порядок обхода звезды
vec2 vert(int i, float R) {
    float a = radians(90.0 + 72.0 * float(i));
    return vec2(cos(a), sin(a)) * R;
}
int ordi(int i) {
    return int(mod(float(2 * i), 5.0));
}
// звёзды одного слоя: ячейка, в ней (может быть) звезда
vec3 stars(vec2 p, float scale, float density, float t) {
    vec2 g = p * scale;
    vec2 id = floor(g), f = fract(g) - 0.5;
    float h = hash(id);
    if (h > density)
        return vec3(0.0);
    vec2 off = vec2(hash(id + 7.1), hash(id + 3.3)) - 0.5;
    float d = length(f - off * 0.7);
    float tw = 0.55 + 0.45 * sin(t * (1.0 + 3.0 * hash(id + 1.7)) + 6.28 * hash(id + 9.2));
    float b = smoothstep(0.08, 0.0, d) * tw + smoothstep(0.35, 0.0, d) * 0.08 * tw;
    vec3 c = mix(vec3(1.0, 0.82, 0.75), vec3(1.0, 0.45, 0.35), hash(id + 4.4));
    return c * b;
}

void main() {
    float aspect = size.x / size.y;
    vec2 uv = qt_TexCoord0;
    vec2 p = (uv - 0.5) * vec2(aspect, 1.0);
    float t = time;

    // ── туманность: fbm, завихрённый сам собой, медленно течёт ──
    vec2 np = p * 1.7;
    vec2 q = vec2(fbm(np + vec2(0.0, 0.0) + 0.010 * t), fbm(np + vec2(5.2, 1.3) - 0.008 * t));
    vec2 r = vec2(fbm(np + 3.5 * q + vec2(1.7, 9.2) + 0.015 * t), fbm(np + 3.5 * q + vec2(8.3, 2.8) - 0.012 * t));
    float f = fbm(np + 3.0 * r);
    // плотнее к центру и к диагонали, пусто по краям
    float core = exp(-dot(p * vec2(0.9, 1.25), p * vec2(0.9, 1.25)) * 2.2);
    float dens = smoothstep(0.25, 1.0, f * (0.55 + 0.9 * core) + 0.25 * length(r));
    // тёмные пылевые прожилки
    float dust = smoothstep(0.45, 0.75, fbm(np * 2.3 + 2.0 * q - 0.006 * t));

    vec3 col = vec3(0.012, 0.004, 0.007);
    col = mix(col, vec3(0.20, 0.01, 0.04), smoothstep(0.0, 0.5, dens));
    col = mix(col, vec3(0.62, 0.04, 0.09), smoothstep(0.35, 0.85, dens) * 0.85);
    col = mix(col, vec3(1.00, 0.32, 0.14), smoothstep(0.7, 1.0, dens) * (0.5 + 0.5 * length(q)) * 0.7);
    col += vec3(0.55, 0.06, 0.25) * pow(clamp(r.y, 0.0, 1.0), 4.0) * core * 0.6;   // пурпурные отсветы
    col *= 1.0 - dust * 0.65;

    // ── звёзды: три слоя ──
    col += stars(p, 22.0, 0.30, t) * 0.55;
    col += stars(p + 3.1, 48.0, 0.22, t * 1.3) * 0.40;
    col += stars(p + 7.7, 110.0, 0.18, t * 1.7) * 0.30;

    // ── перевёрнутая пентаграмма-созвездие ──
    float R = 0.30;
    float breathe = 0.75 + 0.25 * sin(t * 0.6);
    float lines = 1e3;
    for (int i = 0; i < 5; i++)
        lines = min(lines, seg(p, vert(ordi(i), R), vert(ordi(i + 1), R)));
    float ring = abs(length(p) - R * 1.12);
    float ln = smoothstep(0.0022, 0.0, lines) * 0.55 + exp(-lines * 140.0) * 0.22;
    float rg = smoothstep(0.0018, 0.0, ring) * 0.35 + exp(-ring * 160.0) * 0.12;
    vec3 sigilCol = vec3(1.0, 0.16, 0.20);
    col += sigilCol * (ln + rg) * breathe * (1.0 + 1.5 * glow);

    // искра бежит по звезде: 5 отрезков за 10 с
    float path = mod(t * 0.5, 5.0);
    int si = int(floor(path));
    vec2 sp = mix(vert(ordi(si), R), vert(ordi(si + 1), R), fract(path));
    float sd = length(p - sp);
    col += vec3(1.0, 0.55, 0.35) * (exp(-sd * 260.0) * 1.2 + exp(-sd * 45.0) * 0.18);

    // яркие звёзды в вершинах с лучами
    for (int i = 0; i < 5; i++) {
        vec2 d = p - vert(i, R);
        float l = length(d);
        float tw = 0.8 + 0.2 * sin(t * 2.3 + float(i) * 1.7);
        float spikes = exp(-abs(d.x) * 900.0) * exp(-abs(d.y) * 35.0) + exp(-abs(d.y) * 900.0) * exp(-abs(d.x) * 35.0);
        col += vec3(1.0, 0.75, 0.65) * (exp(-l * 320.0) * 1.4 + exp(-l * 40.0) * 0.25 + spikes * 0.5) * tw * (1.0 + glow);
    }

    // ── метеор раз в ~23 с ──
    float mp = 23.0;
    float mi = floor(t / mp), mt = fract(t / mp) * mp;
    if (mt < 1.1) {
        vec2 a = vec2(hash(vec2(mi, 1.0)) * aspect - aspect * 0.5, -0.55 + 0.3 * hash(vec2(mi, 2.0)));
        vec2 dir = normalize(vec2(hash(vec2(mi, 3.0)) - 0.5, 0.6));
        vec2 head = a + dir * mt * 0.9;
        float md = seg(p, head - dir * 0.18, head);
        float along = clamp(dot(p - (head - dir * 0.18), dir) / 0.18, 0.0, 1.0);
        col += vec3(1.0, 0.45, 0.30) * exp(-md * 900.0) * along * (1.0 - mt / 1.1) * 1.4;
    }

    // виньетка
    col *= 1.0 - 0.55 * smoothstep(0.35, 1.05, length(p * vec2(0.85, 1.0)));
    // плёночное зерно против полос в градиентах
    col += (hash(uv * size + fract(t)) - 0.5) / 255.0 * 2.0;
    fragColor = vec4(col, 1.0) * qt_Opacity;
}
