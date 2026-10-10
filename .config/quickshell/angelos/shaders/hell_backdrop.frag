#version 440
// Hell's backdrop (modules/background/WallpaperView while Theme.hell): the circle lays its
// dark over whatever wallpaper there is (HellLook.backdrop) — the colour drained a little,
// most of the light taken, the edges closing in — and its ambient on top, still but for the
// rare event (services/HellAmbient: `event` 0 → 1 → 0, `phase` 0 → 1 over a few seconds):
//   1 fog     grey banks low down              · they drift a little
//   2 wind    thin diagonal streaks             · a gust runs along them
//   3 rain    sparse vertical streaks           · it falls
//   4 dust    a few dull gold motes             · they rise and one glints
//   5 ripple  dark water at the foot            · something long moves under it
//   6 embers  a few embers at the foot          · they rise and glow
//   7 sand    a red haze over the ground        · the heat shimmers across it
//   8 pitch   only the dark                     · two eyes open in it, and close
//   9 ice     rime along the screen's edges     · it creeps a little further
// Whole art pixels (`cell`), an ordered dither for the soft parts: it stays pixel art.
// Drawn once per wallpaper, and ten times a second while an event lasts — nothing else.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float dim;       // 0..1: how much of the light the dark takes
    float desat;     // 0..1: how much of the colour drains
    float vignette;  // 0..1: how far the edges close in
    float cell;      // one art pixel, in screen pixels
    vec2 resolution;
    vec4 tint;       // the dark itself
    float kind;      // the ambient, 0 = none
    float event;     // 0..1..0
    float phase;     // 0..1 through the event
    float seed;
    vec4 light;      // the circle's dim ink (fog, rain, rime)
    vec4 accent;     // its one accent (embers, eyes, glints)
};
layout(binding = 1) uniform sampler2D source;

float bayer2(vec2 a) {
    a = floor(a);
    return fract(a.x / 2.0 + a.y * a.y * 0.75);
}
float bayer4(vec2 a) {
    return bayer2(0.5 * a) * 0.25 + bayer2(a);
}
float hash(vec2 p) {
    return fract(sin(dot(p + seed * 1.37, vec2(12.9898, 78.233))) * 43758.5453);
}
float vnoise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
// a soft amount drawn as a dither: on or off per art pixel
float dith(float a, vec2 px) {
    return step(bayer4(px) + 0.001, a);
}

void main() {
    vec4 s = texture(source, qt_TexCoord0);
    vec3 rgb = s.rgb;
    float l = dot(rgb, vec3(0.299, 0.587, 0.114));
    rgb = mix(rgb, vec3(l), desat);
    rgb = mix(rgb, tint.rgb, dim);

    float c = max(1.0, cell);
    vec2 px = floor(qt_TexCoord0 * resolution / c);      // the art pixel
    vec2 cells = max(vec2(1.0), floor(resolution / c));
    vec2 uv = (px + 0.5) / cells;                         // 0..1 on the art grid
    int k = int(kind + 0.5);

    if (k == 1) {
        // fog: banks in the lower half, drifting right with the event
        // (stepped in four bands along the noise's contours: pixel-art fog, not a screen door)
        float n = vnoise(vec2(px.x / 26.0 - phase * 3.0 * event, px.y / 7.0)) * 0.6 + vnoise(px / 9.0) * 0.4;
        float a = clamp((uv.y - 0.45) * 1.6, 0.0, 1.0) * n;
        rgb = mix(rgb, light.rgb, floor(a * 4.0) / 4.0 * 0.22);
    } else if (k == 2) {
        // wind: short streaks along the diagonal, a gust lights them
        vec2 d = vec2(px.x + px.y * 2.0, px.y);
        float lane = floor(d.y / 3.0);
        float run = fract((d.x + lane * 17.0) / 23.0 - phase * 2.0 * event);
        float on = step(0.86, hash(vec2(lane, floor((d.x + lane * 17.0) / 23.0)))) * step(run, 0.35) * step(mod(px.y, 3.0), 0.5);
        rgb = mix(rgb, light.rgb, on * (0.18 + 0.4 * event));
    } else if (k == 3) {
        // rain: thin columns, still — falling while the event lasts
        float col = hash(vec2(px.x, 3.0));
        float y = px.y - phase * cells.y * 0.6 * step(0.01, event);
        float drop = step(0.93, col) * step(fract((y + col * 97.0) / 19.0), 0.28);
        rgb = mix(rgb, light.rgb, drop * (0.16 + 0.3 * event));
    } else if (k == 4) {
        // dust: dull gold motes; they rise a little, one glints
        vec2 q = vec2(px.x, px.y + phase * 6.0 * event);
        float m = step(0.996, hash(floor(q)));
        float glint = step(0.9995, hash(floor(q) + 7.0)) * event;
        rgb = mix(rgb, accent.rgb, m * 0.35 + glint * 0.6);
    } else if (k == 5) {
        // the Styx: dark water at the foot, lines on it; something long moves beneath
        float water = step(0.8, uv.y);
        float lines = step(0.82, vnoise(vec2(px.x / 9.0, px.y))) * step(mod(px.y, 2.0), 0.5);
        rgb = mix(rgb, tint.rgb, water * 0.5);
        rgb = mix(rgb, light.rgb, water * lines * 0.14);
        vec2 body = vec2(mix(-0.2, 1.2, phase), 0.9);
        float shape = length((uv - body) * vec2(1.0, 6.0));
        rgb = mix(rgb, tint.rgb * 0.4, water * event * dith(clamp(1.0 - shape * 3.5, 0.0, 1.0), px));
    } else if (k == 6) {
        // embers at the foot: a few, dim; they rise and glow with the event
        vec2 q = vec2(px.x, px.y + phase * 14.0 * event);
        float e = step(0.9965, hash(floor(q))) * step(0.72, uv.y);
        rgb = mix(rgb, accent.rgb, e * (0.4 + 0.5 * event));
    } else if (k == 7) {
        // burning sand: a red haze over the ground, a shimmer runs across
        float haze = clamp((uv.y - 0.7) * 3.0, 0.0, 1.0) * (0.6 + 0.4 * vnoise(px / 7.0));
        float band = step(abs(uv.x - phase), 0.06) * event;
        rgb = mix(rgb, accent.rgb * 0.5, floor(haze * (0.6 + 0.4 * band) * 4.0) / 4.0 * 0.35);
    } else if (k == 8) {
        // pitch: in the dark of a lower corner two eyes open with the event, and close
        vec2 e1 = floor(cells * vec2(0.13 + seed * 0.003, 0.78));
        float lid = event > 0.25 ? 1.0 : 0.0;
        float eye = (step(abs(px.x - e1.x), 0.5) + step(abs(px.x - e1.x - 4.0), 0.5)) * step(abs(px.y - e1.y), 0.5);
        rgb = mix(rgb, accent.rgb, eye * lid * 0.9);
    } else if (k == 9) {
        // ice: rime along the screen's edges; it creeps a little with the event
        vec2 m = min(px, cells - 1.0 - px);
        float edge = min(m.x, m.y);
        float reach = 2.0 + floor(hash(vec2(floor(px.x / 5.0), floor(px.y / 5.0))) * 3.0) + floor(event * 2.0);
        float r = step(edge, reach) * step(0.45, hash(px));
        rgb = mix(rgb, light.rgb, r * 0.4);
    }

    // the vignette, stepped and dithered in art pixels
    vec2 d = (qt_TexCoord0 - 0.5) * vec2(resolution.x / max(1.0, resolution.y), 1.0);
    float v = clamp((length(d) - 0.35) / 0.55, 0.0, 1.0) * vignette;
    float q = floor(v * 5.0 + bayer4(px)) / 5.0;
    rgb = mix(rgb, tint.rgb, clamp(q, 0.0, 1.0));
    fragColor = vec4(rgb * s.a, s.a) * qt_Opacity;
}
