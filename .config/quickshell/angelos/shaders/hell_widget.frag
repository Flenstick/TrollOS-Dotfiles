#version 440
// Desktop widgets between heaven and hell (DesktopWidgetHost).
//   recolor  a plugin that doesn't draw hell itself is re-inked in the circle's palette
//            (uniforms from Theme.hell*): light → bone, mid → blood, dark → the body,
//            saturated → the one accent — a few flat colours, like the bar's content.
//   burn     0 → 1 the widget goes over (DesktopWidgets.burn); the realm flips at 0.5.
//            mode 0, into hell: the old look burns from the edges in behind a glowing
//            front, then the new one re-forms from the middle out, still glowing.
//            mode 1, back to heaven: the hell look turns to ash and the wind blows it
//            off to the right and up, then a line of light sweeps down and the heaven
//            look comes up behind it from white-gold.
// Everything happens on whole art pixels (`cell`), so it stays pixel art.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float burn;
    float mode;
    float recolor;
    float seed;
    vec2 cell;      // one art pixel in uv
    vec4 box;       // the window frame in uv: x0, y0, x1, y1 (the rest is shadow / trim)
    vec4 cDark;     // the circle's palette (Theme.hellBody, hellBlood, hellAccent, hellFlame, hellText)
    vec4 cBlood;
    vec4 cAccent;
    vec4 cFlame;
    vec4 cBone;
};
layout(binding = 1) uniform sampler2D source;

float hash(vec2 p) {
    return fract(sin(dot(p + seed, vec2(127.1, 311.7))) * 43758.5453);
}
// smooth blobs a few art pixels across: a wavy burn line instead of static
float blobs(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

#define OBSIDIAN cDark.rgb
#define BLOOD cBlood.rgb
#define EMBER cAccent.rgb
#define FLAME cFlame.rgb
#define BONE cBone.rgb

// stepped, like the bar's content: a few flat colours, no gradients
vec3 hellMap(vec3 rgb) {
    float l = dot(rgb, vec3(0.299, 0.587, 0.114));
    float sat = max(rgb.r, max(rgb.g, rgb.b)) - min(rgb.r, min(rgb.g, rgb.b));
    if (sat > 0.32 && l > 0.16)
        return EMBER;
    if (l < 0.2)
        return OBSIDIAN;
    if (l < 0.6)
        return BLOOD;
    return BONE;
}

vec4 sampleAt(vec2 uv) {
    vec4 c = texture(source, uv);
    if (recolor > 0.0 && c.a > 0.003)
        c.rgb = mix(c.rgb, hellMap(c.rgb / c.a) * c.a, recolor);
    return c;
}

void main() {
    vec2 uv = qt_TexCoord0;
    vec2 g = floor(uv / cell);
    vec2 q = ((g + 0.5) * cell - box.xy) / max(box.zw - box.xy, vec2(1e-4));
    // 0 at the frame's edge (and outside it), 1 in the middle
    float edge = clamp(min(min(q.x, 1.0 - q.x), min(q.y, 1.0 - q.y)) * 2.0, 0.0, 1.0);
    float n = hash(g);
    vec4 c = sampleAt(uv);

    if (burn < 1.0) {
        if (mode < 0.5) {
            // ---- into hell: burn away from the edges, then re-form from the middle ----
            float t = burn < 0.5 ? burn * 2.0 : (1.0 - burn) * 2.0;     // 0 → 1 → 0
            float k = edge * 0.72 + blobs(g / 5.0) * 0.24 + n * 0.04;  // what burns first
            float d = k - t * 1.1;
            if (d < -0.04) {
                c = vec4(0.0);
            } else if (d < 0.0) {
                // the glowing line: whatever was there burns, a pixel flickering here and there
                float hot = step(0.85, hash(g + floor(burn * 20.0)));
                c = vec4(mix(mix(EMBER, BLOOD, step(-0.02, -d)), FLAME, hot), 1.0) * step(0.05, c.a);
            } else if (d < 0.06) {
                // charring just ahead of it, like paper
                float a = 1.0 - d / 0.06;
                c.rgb = mix(c.rgb, vec3(0.09, 0.025, 0.02) * c.a, a * 0.9);
            }
        } else {
            // ---- back to heaven: ash in the wind, then light from above ----
            if (burn < 0.5) {
                float t = burn * 2.0;
                float k = blobs(g / 4.0) * 0.35 + n * 0.1 + (1.0 - q.x) * 0.4 + q.y * 0.15;    // the right side goes first
                float gone = t * 1.25 - k;
                if (gone > 0.1) {
                    // blown off: a few grey specks drifting right and up from where they were
                    float s = (gone - 0.1) * 0.3;
                    vec2 from = uv - vec2(s, -s * 0.5);
                    vec4 a = sampleAt(from);
                    float speck = step(0.8, hash(floor(from / cell))) * step(0.3, a.a) * (1.0 - smoothstep(0.1, 0.5, gone));
                    c = vec4(vec3(0.5) * speck, speck);
                } else if (gone > -0.12) {
                    // turning to ash
                    float a = smoothstep(-0.12, 0.1, gone);
                    float l = c.a > 0.003 ? dot(c.rgb / c.a, vec3(0.333)) : 0.0;
                    c.rgb = mix(c.rgb, vec3(0.28 + l * 0.35) * c.a, a);
                }
            } else {
                // a line of light sweeps down; behind it the widget comes up from white-gold
                float t = (burn - 0.5) * 2.0;
                float front = t * 1.3 - 0.12;
                float y = q.y + n * 0.06;
                if (y > front) {
                    c = vec4(0.0);
                } else {
                    float behind = clamp((front - y) / 0.3, 0.0, 1.0);
                    c.rgb = mix(vec3(1.0, 0.95, 0.78) * c.a, c.rgb, behind);
                    if (front - y < 0.03 && c.a > 0.05)
                        c = vec4(1.0, 0.93, 0.6, 1.0);
                }
            }
        }
    }
    fragColor = c * qt_Opacity;
}
